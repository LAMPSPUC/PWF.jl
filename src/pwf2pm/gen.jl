function _handle_pmin(pwf_data::Dict, bus_i::Int, dict_dger)
    if haskey(pwf_data, "DGER") && haskey(dict_dger, bus_i)
        bus = dict_dger[bus_i]
        return bus["MINIMUM ACTIVE GENERATION"]
    end    
    bus = pwf_data["DBAR"]["$bus_i"]
    return bus["ACTIVE GENERATION"]
end

function _handle_pmax(pwf_data::Dict, bus_i::Int, dict_dger)
    if haskey(pwf_data, "DGER") && haskey(dict_dger, bus_i)
        bus = dict_dger[bus_i]
        return bus["MAXIMUM ACTIVE GENERATION"]
    end    
    bus = pwf_data["DBAR"]["$bus_i"]
    return bus["ACTIVE GENERATION"]
end

function _create_dict_dger(data::Dict)
    dict_dger = Dict{Int, Any}()

    for (k,v) in data
        sub_data = Dict{String, Any}()
        sub_data["MINIMUM ACTIVE GENERATION"] = v["MINIMUM ACTIVE GENERATION"]
        sub_data["MAXIMUM ACTIVE GENERATION"] = v["MAXIMUM ACTIVE GENERATION"]
        dict_dger[v["NUMBER"]] = sub_data
    end
    return dict_dger
end

function _pwf2pm_generator!(pm_data::Dict, pwf_data::Dict, bus::Dict)
    sub_data = Dict{String,Any}()

    sub_data["gen_bus"] = bus["NUMBER"]
    sub_data["gen_status"] = 1
    sub_data["pg"] = bus["ACTIVE GENERATION"]
    sub_data["qg"] = bus["REACTIVE GENERATION"]
    sub_data["vg"] = pm_data["bus"]["$(bus["NUMBER"])"]["vm"]
    sub_data["mbase"] = _handle_base_mva(pwf_data)

    dict_dger = haskey(pwf_data, "DGER") ? _create_dict_dger(pwf_data["DGER"]) : nothing
    sub_data["pmin"] = _handle_pmin(pwf_data, bus["NUMBER"], dict_dger)
    sub_data["pmax"] = _handle_pmax(pwf_data, bus["NUMBER"], dict_dger)

    sub_data["qmin"] = haskey(bus, "MINIMUM REACTIVE GENERATION") ? bus["MINIMUM REACTIVE GENERATION"] : bus["REACTIVE GENERATION"]
    sub_data["qmax"] = haskey(bus, "MAXIMUM REACTIVE GENERATION") ? bus["MAXIMUM REACTIVE GENERATION"] : bus["REACTIVE GENERATION"]

    # Default Cost functions
    sub_data["model"] = 2
    sub_data["startup"] = 0.0
    sub_data["shutdown"] = 0.0
    sub_data["ncost"] = 2
    sub_data["cost"] = [1.0, 0.0]

    sub_data["source_id"] = ["generator", sub_data["gen_bus"], "1 "]
    sub_data["index"] = length(pm_data["gen"]) + 1
    
    idx = string(sub_data["index"])
    pm_data["gen"][idx] = sub_data
end

function _pwf2pm_generator!(pm_data::Dict, pwf_data::Dict)

    if !haskey(pwf_data, "DGER")
        @warn("DGER not found, setting pmin and pmax as the bar active generation")
    end

    pm_data["gen"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for (i,bus) in pwf_data["DBAR"]
            if bus["ACTIVE GENERATION"] > 0.0 || bus["REACTIVE GENERATION"] != 0.0 || bus["TYPE"] == bus_type_raw_to_pwf[bus_type_str_to_num["PV"]]
                _pwf2pm_generator!(pm_data, pwf_data, bus)
            end
        end
    end
end