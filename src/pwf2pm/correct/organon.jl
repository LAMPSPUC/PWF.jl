function _pwf2pm_corrections_PV!(pm_data::Dict, pwf_data::Dict, software::Organon)
    for (i, bus) in pm_data["bus"]
        if bus_type_num_to_str[bus["bus_type"]] == "PV"
            filters = [
                gen -> element_status[gen["gen_status"]] == "ON", 
                gen -> gen["qmin"] == gen["qmax"]
            ]
            if !isempty(generators_from_bus(pm_data, parse(Int, i); filters = filters))
                bus["bus_type"] = bus_type_str_to_num["PQ"]
                if isempty(load_from_bus(pm_data, parse(Int, i)))
                    _pwf2pm_load!(pm_data, pwf_data, parse(Int,i))
                end
                @warn "Active generator with QMIN = QMAX found in a PV bus number $i. Changing bus type from PV to PQ."
            end
        end
    end
end

function _pwf2pm_corrections_PQ!(pm_data::Dict, software::Organon)
    for (i, bus) in pm_data["bus"]
        if bus_type_num_to_str[bus["bus_type"]] == "PQ"
            filters = [
                gen -> element_status[gen["gen_status"]] == "ON", #1
                gen -> gen["qmin"] < gen["qmax"],                 #2
                gen -> gen["qmin"] == gen["qmax"]                 #3
            ]
            gen_keys_case1 = generators_from_bus(pm_data, parse(Int, i); filters = filters[[1,2]])
            gen_keys_case2 = generators_from_bus(pm_data, parse(Int, i); filters = filters[[1,3]])

            if !isempty(gen_keys_case1)
                # change bus type to PV
                bus["bus_type"] = bus_type_str_to_num["PV"]
                @warn "Active generator with QMIN < QMAX found in a PQ bus. Changing bus $i type to PV."
            elseif !isempty(gen_keys_case2)
                # change generator status to off and sum load power with gen power
                Pg, Qg = sum_generators_power_and_turn_off(pm_data, gen_keys_case2)
                load_key = load_from_bus(pm_data, parse(Int, i))
                @assert length(load_key) == 1
                # sum load power with the negative of generator power
                pm_data["load"][load_key[1]]["pd"] += - Pg
                pm_data["load"][load_key[1]]["qd"] += - Qg                 
                @warn "Active generator with QMIN = QMAX found in PQ bus $i. Adding generator power " *
                    "to load power and changing generator status to off."
            end
        end
    end
    return
end

function _pwf2pm_corrections_shunt!(pm_data::Dict, software::Organon)
    for (s, shunt) in pm_data["shunt"]
        bus = pm_data["bus"]["$(shunt["shunt_bus"])"]
        bus_type = bus["bus_type"]
        
        if !(bus_type_num_to_str[bus_type] == "PQ" && shunt["shunt_control_type"] == 2) # Discrete
           _fix_shunt_voltage_bounds(shunt, pm_data)
        end
    end
end