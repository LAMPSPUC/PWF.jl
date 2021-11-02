function handle_specified_value(element::Dict, spec::String, min::String, max::String)
    spec_value = element[spec]

    if (element[min] === nothing || element[max] === nothing)
        return spec_value
    end
    if (element[min] == element[min] == 0.0)
        return spec_value
    end

    min_value  = element[min] 
    max_value  = element[max]
    if (spec_value - min_value) < 0
        return min_value
    elseif (max_value - spec_value < 0)
        return max_value
    end

    return spec_value
end

transformers_in_pm_data(pm_data::Dict) = Dict([k => transformer for (k, transformer) in network["branch"] if transformer["transformer"] == true])

function _pwf2pm_corrections_gen!(pm_data::Dict, pwf_data::Dict, software::ANAREDE)
    for (i, gen) in pm_data["gen"]
        gen["qg"] = handle_specified_value(gen, "qg", "qmin", "qmax")
        gen["pg"] = handle_specified_value(gen, "pg", "pmin", "pmax")
    end
end

function _pwf2pm_corrections_shunt!(pm_data::Dict, pwf_data::Dict, software::ANAREDE)
    for (i, shunt) in pm_data["shunt"]
        shunt["bs"] = handle_specified_value(gen, "bs", "bsmin", "bsmax")

        bus = pm_data["bus"]["$(shunt["shunt_bus"])"]
        bus_type = bus["bus_type"]
        
        if !(bus_type_num_to_str[bus_type] == "PQ" && shunt["shunt_control_type"] == 2) # Discrete
           _fix_shunt_voltage_bounds(shunt, pm_data)
        end
    end
end

function _pwf2pm_corrections_shunt!(pm_data::Dict, software::ANAREDE)
end

function _pwf2pm_corrections_transformer!(pm_data::Dict, pwf_data::Dict, software::ANAREDE)
    for (i, transformer) in transformers_in_pm_data(pm_data)
        transformer["tap"] = handle_specified_value(gen, "tap", "tapmin", "tapmax")
    end
end

function _pwf2pm_corrections_PV!(pm_data::Dict, pwf_data::Dict, software::ANAREDE)
    # in ANAREDE, PV bus with generation QMIN == QMAX are kept as PV
end

function _pwf2pm_corrections_PQ!(pm_data::Dict, software::ANAREDE)
    for (i, bus) in pm_data["bus"]
        if bus_type_num_to_str[bus["bus_type"]] == "PQ"
            filters = [
                gen -> element_status[gen["gen_status"]] == "ON", #1
                gen -> gen["qmin"] < gen["qmax"],                 #2
                gen -> gen["qmin"] == gen["qmax"],                #3
                gen -> gen["qmin"] != 0.0,                        #4
                gen -> gen["qmin"] == 0.0,                        #5
            ]
            gen_keys_case1 = generators_from_bus(pm_data, parse(Int, i); filters = filters[[1,2]])
            gen_keys_case2 = generators_from_bus(pm_data, parse(Int, i); filters = filters[[1,3,4]])
            gen_keys_case3 = generators_from_bus(pm_data, parse(Int, i); filters = filters[[1,3,5]])

            if !isempty(gen_keys_case1)
                error("ANAREDE: Active generator with QMIN < QMAX found in a PQ bus. Verify data from Bus $i.")
            elseif !isempty(gen_keys_case2)
                error("ANAREDE: Active generator with QMIN = QMAX != 0 found in PQ bus. Verify data from Bus $i.")
            elseif !isempty(gen_keys_case3)
                # change generator status to off and sum load power with gen power
                Pg, Qg = sum_generators_power_and_turn_off(pm_data, gen_keys_case3)
                load_key = load_from_bus(pm_data, parse(Int, i))
                @assert length(load_key) == 1
                # sum load power with the negative of generator power
                pm_data["load"][load_key[1]]["pd"] += - Pg
                pm_data["load"][load_key[1]]["qd"] += - Qg                 
                @warn "Active generator with QMIN = QMAX = 0 found in PQ bus $i. Adding generator power " *
                            "to load power and changing generator status to off."
            end
        end
    end
end

