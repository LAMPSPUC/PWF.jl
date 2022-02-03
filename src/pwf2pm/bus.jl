function _handle_base_kv(pwf_data::Dict, bus::Dict, dict_dgbt)
    group_identifier = bus["BASE VOLTAGE GROUP"]
    if haskey(pwf_data, "DGBT")
        if haskey(dict_dgbt, group_identifier)
            group = dict_dgbt[group_identifier]
            return group["VOLTAGE"]
        elseif length(pwf_data["DGBT"]) == 1
            return pwf_data["DGBT"]["1"]["VOLTAGE"]
        end
    end
    return 1.0
end

function _handle_vmin(pwf_data::Dict, bus::Dict, dict_dglt)
    group_identifier = bus["VOLTAGE LIMIT GROUP"]
    if haskey(pwf_data, "DGLT") 
        if haskey(dict_dglt, group_identifier)
            group = dict_dglt[group_identifier]
            return group["LOWER BOUND"]
        elseif length(pwf_data["DGLT"]) == 1
            return pwf_data["DGLT"]["1"]["LOWER BOUND"]
        end
    end
    return 0.9    
end

function _handle_vmax(pwf_data::Dict, bus::Dict, dict_dglt)
    group_identifier = bus["VOLTAGE LIMIT GROUP"] 
    if haskey(pwf_data, "DGLT") 
        if haskey(dict_dglt, group_identifier)
            group = dict_dglt[group_identifier]
            return group["UPPER BOUND"]
        elseif length(pwf_data["DGLT"]) == 1
            return pwf_data["DGLT"]["1"]["UPPER BOUND"]
        end
    end
    return 1.1    
end

function _handle_bus_type(bus::Dict)
    bus_type = bus["TYPE"]
    dict_bus_type = Dict(
        0 => 1, 
        3 => 1, # PQ
        1 => 2, # PV
        2 => 3 # Referência
    )
    if bus["STATUS"] == 'L'
        return dict_bus_type[bus_type]
    elseif bus["STATUS"] == 'D'
        return 4
    end
end

function _create_dict_dglt(data::Dict)
    dict_dglt = Dict{String, Any}()

    for (k,v) in data
        sub_data = Dict{String, Any}()
        sub_data["LOWER BOUND"] = v["LOWER BOUND"]
        sub_data["UPPER BOUND"] = v["UPPER BOUND"]
        sub_data["LOWER EMERGENCY BOUND"] = v["LOWER EMERGENCY BOUND"]
        sub_data["UPPER EMERGENCY BOUND"] = v["UPPER EMERGENCY BOUND"]
        dict_dglt[v["GROUP"]] = sub_data
    end
    return dict_dglt
end

function _create_dict_dgbt(data::Dict)
    dict_dgbt = Dict{String, Any}()

    for (k,v) in data
        sub_data = Dict{String, Any}("VOLTAGE" => v["VOLTAGE"])
        dict_dgbt[v["GROUP"]] = sub_data
    end
    return dict_dgbt
end

function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict, bus::Dict, dict_dgbt, dict_dglt; add_control_data::Bool=false)
    sub_data = Dict{String,Any}()

    sub_data["bus_i"] = bus["NUMBER"]
    sub_data["bus_type"] = _handle_bus_type(bus)
    sub_data["area"] = pop!(bus, "AREA")
    sub_data["vm"] = bus["VOLTAGE"]
    sub_data["va"] = pop!(bus, "ANGLE")
    sub_data["zone"] = 1
    sub_data["name"] = pop!(bus, "NAME")

    sub_data["source_id"] = ["bus", "$(bus["NUMBER"])"]
    sub_data["index"] = bus["NUMBER"]

    sub_data["base_kv"] = _handle_base_kv(pwf_data, bus, dict_dgbt)
    sub_data["vmin"] = _handle_vmin(pwf_data, bus, dict_dglt)
    sub_data["vmax"] = _handle_vmax(pwf_data, bus, dict_dglt)

    if add_control_data
        sub_data["control_data"] = Dict{String,Any}()
        sub_data["control_data"]["voltage_controlled_bus"] = bus["CONTROLLED BUS"]
        sub_data["control_data"]["vmmin"] = sub_data["vmin"]
        sub_data["control_data"]["vmmax"] = sub_data["vmax"]
    end

    idx = string(sub_data["index"])
    pm_data["bus"][idx] = sub_data
end

function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict; add_control_data::Bool=false)

    dict_dglt = haskey(pwf_data, "DGLT") ? _create_dict_dglt(pwf_data["DGLT"]) : nothing
    isa(dict_dglt, Dict) && length(dict_dglt) == 1 ? Memento.warn(_LOGGER, "Only one limit voltage group definded, each bus will be considered as part of the group $(pwf_data["DGLT"]["1"]["GROUP"]), regardless of its defined group") : nothing
    dict_dgbt = haskey(pwf_data, "DGBT") ? _create_dict_dgbt(pwf_data["DGBT"]) : nothing
    isa(dict_dgbt, Dict) && length(dict_dgbt) == 1 ? Memento.warn(_LOGGER, "Only one base voltage group definded, each bus will be considered as part of the group $(pwf_data["DGBT"]["1"]["GROUP"]), regardless of its defined group") : nothing

    pm_data["bus"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for (i,bus) in pwf_data["DBAR"]
            _pwf2pm_bus!(pm_data, pwf_data, bus, dict_dgbt, dict_dglt, add_control_data = add_control_data)
        end
    end
end
