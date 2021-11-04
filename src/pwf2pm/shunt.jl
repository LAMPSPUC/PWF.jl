function _create_new_shunt(sub_data::Dict, pm_data::Dict)
    for (idx, value) in pm_data["shunt"]
        if value["shunt_bus"] == sub_data["shunt_bus"] && value["source_id"][1] == sub_data["source_id"][1]
            return false, idx
        end
    end
    return true    
end

function _handle_bs_bounds(shunt::Dict{String, Any})
    bsmin, bsmax = 0.0, 0.0
    for (i,el) in shunt["REACTANCE GROUPS"]
        if el["REACTANCE"] > 0.0
            bsmax += el["UNITIES"]*el["REACTANCE"]
        elseif el["REACTANCE"] < 0.0
            bsmin += el["UNITIES"]*el["REACTANCE"]
        end
    end
    return bsmin, bsmax
end

function _handle_bs(shunt::Dict{String, Any}; type = "bus")
    bs = 0
    if type == "bus" && shunt["CONTROL MODE"] == 'C'
        bs += shunt["INITIAL REACTIVE INJECTION"]
    else
        for (i,el) in shunt["REACTANCE GROUPS"]
            if el["STATUS"] == 'L'
                bs += el["OPERATING UNITIES"]*el["REACTANCE"]
            end
        end
    end
    return bs
end

function _pwf2pm_DBSH_shunt!(pm_data::Dict, pwf_data::Dict, shunt::Dict)

    shunt_bus = shunt["TO BUS"] === nothing ? shunt["FROM BUS"] : shunt["EXTREMITY"]
    n = count(x -> x["shunt_bus"] == shunt_bus, values(pm_data["shunt"])) 

    sub_data = Dict{String,Any}()
    sub_data["control_info"] = Dict{String,Any}()

    sub_data["control_info"]["section"] = "DBSH"

    sub_data["shunt_bus"] = shunt_bus
    
    sub_data["control_info"]["shunt_type"] = shunt["CONTROL MODE"] == 'F' ? 1 : 2
    sub_data["control_info"]["shunt_control_type"] = shunt["CONTROL MODE"] == 'F' ? 1 : shunt["CONTROL MODE"] == 'D' ? 2 : 3 

    sub_data["gs"] = 0.0
    sub_data["bs"] = _handle_bs(shunt)

    sub_data["control_info"]["vm_min"] = shunt["MINIMUM VOLTAGE"]
    sub_data["control_info"]["vm_max"] = shunt["MAXIMUM VOLTAGE"]

    sub_data["control_info"]["controlled_bus"] = shunt["CONTROLLED BUS"]
    bs_bounds = _handle_bs_bounds(shunt)
    sub_data["control_info"]["bsmin"] = bs_bounds[1]
    sub_data["control_info"]["bsmax"] = bs_bounds[2]
    @assert sub_data["control_info"]["bsmin"] <= sub_data["control_info"]["bsmax"]

    status = pwf_data["DBAR"]["$(sub_data["shunt_bus"])"]["STATUS"]
    if status == 'L'
        sub_data["status"] = 1
    elseif status == 'D'
        sub_data["status"] = 0
    end    

    sub_data["source_id"] = ["switched shunt", sub_data["shunt_bus"], "0$(n+1)"]
    sub_data["index"] = length(pm_data["shunt"]) + 1

    if _create_new_shunt(sub_data, pm_data)[1]
        idx = string(sub_data["index"])
        pm_data["shunt"][idx] = sub_data
    else
        idx = _create_new_shunt(sub_data, pm_data)[2]
        pm_data["shunt"][idx]["gs"] += sub_data["gs"]
        pm_data["shunt"][idx]["bs"] += sub_data["bs"]
        pm_data["shunt"][idx]["control_info"]["bsmin"] += sub_data["control_info"]["bsmin"]
        pm_data["shunt"][idx]["control_info"]["bsmax"] += sub_data["control_info"]["bsmax"]
    end
end

function _pwf2pm_DBSH_shunt!(pm_data::Dict, pwf_data::Dict)
    if haskey(pwf_data, "DBSH")

        for (i,shunt) in pwf_data["DBSH"]
            _pwf2pm_DBSH_shunt!(pm_data, pwf_data, shunt)
        end
    end
end

function _pwf2pm_DCER_shunt!(pm_data::Dict, pwf_data::Dict, shunt::Dict)
    n = count(x -> x["shunt_bus"] == shunt["BUS"], values(pm_data["shunt"])) 

    sub_data = Dict{String,Any}()
    sub_data["control_info"] = Dict{String,Any}()
    
    sub_data["control_info"]["section"] = "DCER"

    sub_data["shunt_bus"] = shunt["BUS"]
    sub_data["gs"]        = 0.0
    sub_data["bs"]        = shunt["REACTIVE GENERATION"]

    sub_data["control_info"]["shunt_type"]         = 2
    sub_data["control_info"]["shunt_control_type"] = 3 

    sub_data["control_info"]["bsmin"] = shunt["MINIMUM REACTIVE GENERATION"]
    sub_data["control_info"]["bsmax"] = shunt["MAXIMUM REACTIVE GENERATION"]

    @assert sub_data["control_info"]["bsmin"] <= sub_data["control_info"]["bsmax"]

    ctrl_bus = pm_data["bus"]["$(shunt["CONTROLLED BUS"])"]
    sub_data["control_info"]["vm_min"] = ctrl_bus["vm"]
    sub_data["control_info"]["vm_max"] = ctrl_bus["vm"]
    sub_data["control_info"]["controlled_bus"] = shunt["CONTROLLED BUS"]

    status   = pwf_data["DBAR"]["$(sub_data["shunt_bus"])"]["STATUS"]

    if status == 'L'
        sub_data["status"] = 1
    elseif status == 'D'
        sub_data["status"] = 0
    end    

    sub_data["source_id"] = ["switched shunt", sub_data["shunt_bus"], "0$(n+1)"]
    sub_data["index"]     = length(pm_data["shunt"]) + 1

    if _create_new_shunt(sub_data, pm_data)[1]
        idx = string(sub_data["index"])
        pm_data["shunt"][idx] = sub_data
    else
        idx = _create_new_shunt(sub_data, pm_data)[2]
        pm_data["shunt"][idx]["gs"] += sub_data["gs"]
        pm_data["shunt"][idx]["bs"] += sub_data["bs"]
        pm_data["shunt"][idx]["control_info"]["bsmin"] += sub_data["control_info"]["bsmin"]
        pm_data["shunt"][idx]["control_info"]["bsmax"] += sub_data["control_info"]["bsmax"]
    end
end

function _pwf2pm_DCER_shunt!(pm_data::Dict, pwf_data::Dict)
    # Assumption - the reactive generation is already considering the number of unities
    if haskey(pwf_data, "DCER")

        for (i,shunt) in pwf_data["DCER"]
            _pwf2pm_DCER_shunt!(pm_data, pwf_data, shunt)
        end
    end
end

function _pwf2pm_DBAR_shunt!(pm_data::Dict, pwf_data::Dict, bus::Dict)
    sub_data = Dict{String,Any}()
    sub_data["control_info"] = Dict{String,Any}()

    sub_data["control_info"]["section"] = "DBAR"
    
    sub_data["shunt_bus"] = bus["NUMBER"]
    sub_data["gs"] = 0.0        
    sub_data["bs"] =  bus["TOTAL REACTIVE POWER"] 

    sub_data["control_info"]["shunt_type"] = 1
    sub_data["control_info"]["shunt_control_type"] = 1
    
    sub_data["control_info"]["bsmin"] = sub_data["bs"]
    sub_data["control_info"]["bsmax"] = sub_data["bs"]
    @assert sub_data["control_info"]["bsmin"] <= sub_data["control_info"]["bsmax"]

    sub_data["control_info"]["vm_min"] = bus["VOLTAGE"]
    sub_data["control_info"]["vm_max"] = bus["VOLTAGE"]
    sub_data["control_info"]["controlled_bus"] = bus["CONTROLLED BUS"]

    if bus["STATUS"] == 'L'
        sub_data["status"] = 1
    elseif bus["STATUS"] == 'D'
        sub_data["status"] = 0
    end    

    n = count(x -> x["shunt_bus"] == sub_data["shunt_bus"], values(pm_data["shunt"])) 
    sub_data["source_id"] = ["fixed shunt", sub_data["shunt_bus"], "0$(n+1)"]
    sub_data["index"] = length(pm_data["shunt"]) + 1

    idx = string(sub_data["index"])
    pm_data["shunt"][idx] = sub_data
end

function _pwf2pm_DBAR_shunt!(pm_data::Dict, pwf_data::Dict)
     # fixed shunts specified at DBAR
     fixed_shunt_bus = findall(x -> x["TOTAL REACTIVE POWER"] != 0.0, pwf_data["DBAR"])

     for bus in fixed_shunt_bus
        _pwf2pm_DBAR_shunt!(pm_data, pwf_data, pwf_data["DBAR"][bus])
     end 
end

# Assumption - if there are more than one shunt for the same bus we sum their values into one shunt (source: Organon)
# CAUTION: this might be an Organon error
function _pwf2pm_shunt!(pm_data::Dict, pwf_data::Dict)
    pm_data["shunt"] = Dict{String, Any}()

    _pwf2pm_DBAR_shunt!(pm_data, pwf_data)
   
    _pwf2pm_DCER_shunt!(pm_data, pwf_data)

    _pwf2pm_DBSH_shunt!(pm_data, pwf_data)
end