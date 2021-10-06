function _pwf2pm_load!(pm_data::Dict, pwf_data::Dict, i::Int)    
    bus = pwf_data["DBAR"]["$i"]

    sub_data = Dict{String,Any}()

    sub_data["load_bus"] = bus["NUMBER"]
    sub_data["pd"] = pop!(bus, "ACTIVE CHARGE")
    sub_data["qd"] = pop!(bus, "REACTIVE CHARGE")
    sub_data["status"] = 1

    sub_data["source_id"] = ["load", sub_data["load_bus"], "1 "]
    sub_data["index"] = length(pm_data["load"]) + 1

    idx = string(sub_data["index"])
    pm_data["load"][idx] = sub_data
end

function _pwf2pm_load!(pm_data::Dict, pwf_data::Dict, bus::Dict)    
    sub_data = Dict{String,Any}()

    sub_data["load_bus"] = bus["NUMBER"]
    sub_data["pd"] = pop!(bus, "ACTIVE CHARGE")
    sub_data["qd"] = pop!(bus, "REACTIVE CHARGE")
    sub_data["status"] = 1

    sub_data["source_id"] = ["load", sub_data["load_bus"], "1 "]
    sub_data["index"] = length(pm_data["load"]) + 1

    idx = string(sub_data["index"])
    pm_data["load"][idx] = sub_data
end

function _pwf2pm_load!(pm_data::Dict, pwf_data::Dict)

    pm_data["load"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for (i,bus) in pwf_data["DBAR"]
            if bus["ACTIVE CHARGE"] > 0.0 || bus["REACTIVE CHARGE"] > 0.0 || bus["TYPE"] == bus_type_raw_to_pwf[bus_type_str_to_num["PQ"]]
                _pwf2pm_load!(pm_data, pwf_data, bus["NUMBER"])
            end
        end
    end
end
