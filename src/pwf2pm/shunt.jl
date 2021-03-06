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

function _pwf2pm_DBSH_shunt!(pm_data::Dict, pwf_data::Dict, shunt::Dict; add_control_data::Bool=false)

    shunt_bus = shunt["TO BUS"] === nothing ? shunt["FROM BUS"] : shunt["EXTREMITY"]
    n = count(x -> x["shunt_bus"] == shunt_bus, values(pm_data["shunt"])) 

    sub_data = Dict{String,Any}()

    sub_data["shunt_bus"] = shunt_bus

    sub_data["gs"] = 0.0
    sub_data["bs"] = _handle_bs(shunt)

    status = pwf_data["DBAR"]["$(sub_data["shunt_bus"])"]["STATUS"]
    if status == 'L'
        sub_data["status"] = 1
    elseif status == 'D'
        sub_data["status"] = 0
    end    

    if add_control_data
        sub_data["control_data"] = Dict{String,Any}()

        sub_data["control_data"]["section"] = "DBSH"

        
        sub_data["control_data"]["shunt_type"] = shunt["CONTROL MODE"] == 'F' ? 1 : 2
        sub_data["control_data"]["shunt_control_type"] = shunt["CONTROL MODE"] == 'F' ? 1 : shunt["CONTROL MODE"] == 'D' ? 2 : 3 


        sub_data["control_data"]["vmmin"] = shunt["MINIMUM VOLTAGE"]
        sub_data["control_data"]["vmmax"] = shunt["MAXIMUM VOLTAGE"]

        sub_data["control_data"]["controlled_bus"] = shunt["CONTROLLED BUS"]
        bs_bounds = _handle_bs_bounds(shunt)
        sub_data["control_data"]["bsmin"] = bs_bounds[1]
        sub_data["control_data"]["bsmax"] = bs_bounds[2]
        @assert sub_data["control_data"]["bsmin"] <= sub_data["control_data"]["bsmax"]
        sub_data["control_data"]["inclination"] = nothing

        controlled_bus = sub_data["control_data"]["controlled_bus"]
        if sub_data["control_data"]["shunt_control_type"] in [2,3]
            pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_control"] = true
            shunt_section = pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_section"] 
            if isnothing(shunt_section)
                pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_section"] = "DBSH"
            else
                # don't overwrite
            end
        end
    end

    sub_data["source_id"] = ["switched shunt", sub_data["shunt_bus"], "0$(n+1)"]
    sub_data["index"] = length(pm_data["shunt"]) + 1

    idx = string(sub_data["index"])
    pm_data["shunt"][idx] = sub_data
end

function _pwf2pm_DBSH_shunt!(pm_data::Dict, pwf_data::Dict; add_control_data::Bool=false)
    if haskey(pwf_data, "DBSH")

        for (i,shunt) in pwf_data["DBSH"]
            _pwf2pm_DBSH_shunt!(pm_data, pwf_data, shunt, add_control_data = add_control_data)
        end
    end
end

function _pwf2pm_DCER_shunt!(pm_data::Dict, pwf_data::Dict, shunt::Dict; add_control_data::Bool=false)
    n = count(x -> x["shunt_bus"] == shunt["BUS"], values(pm_data["shunt"])) 

    sub_data = Dict{String,Any}()
    sub_data["shunt_bus"] = shunt["BUS"]
    sub_data["gs"]        = 0.0
    sub_data["bs"]        = shunt["REACTIVE GENERATION"]

    status   = pwf_data["DBAR"]["$(sub_data["shunt_bus"])"]["STATUS"]

    if status == 'L'
        sub_data["status"] = 1
    elseif status == 'D'
        sub_data["status"] = 0
    end    

    if add_control_data
        sub_data["control_data"] = Dict{String,Any}()
        
        sub_data["control_data"]["section"] = "DCER"


        sub_data["control_data"]["shunt_type"]         = 2
        sub_data["control_data"]["shunt_control_type"] = 3 

        sub_data["control_data"]["bsmin"] = shunt["MINIMUM REACTIVE GENERATION"]
        sub_data["control_data"]["bsmax"] = shunt["MAXIMUM REACTIVE GENERATION"]

        @assert sub_data["control_data"]["bsmin"] <= sub_data["control_data"]["bsmax"]

        ctrl_bus = pm_data["bus"]["$(shunt["CONTROLLED BUS"])"]
        sub_data["control_data"]["vmmin"] = ctrl_bus["vm"]
        sub_data["control_data"]["vmmax"] = ctrl_bus["vm"]
        sub_data["control_data"]["controlled_bus"] = shunt["CONTROLLED BUS"]
        sub_data["control_data"]["inclination"] = shunt["INCLINATION"]

        controlled_bus = sub_data["control_data"]["controlled_bus"]
        if sub_data["control_data"]["shunt_control_type"] in [2,3]
            pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_control"] = true
            shunt_section = pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_section"] 
            if isnothing(shunt_section)
                pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_section"] = "DCER"
            else
                pm_data["bus"]["$controlled_bus"]["control_data"]["shunt_section"] = "DCER" # DCER always overwrites
            end
        end
    end

    sub_data["source_id"] = ["switched shunt", sub_data["shunt_bus"], "0$(n+1)"]
    sub_data["index"]     = length(pm_data["shunt"]) + 1

    idx = string(sub_data["index"])
    pm_data["shunt"][idx] = sub_data
end

function _pwf2pm_DCER_shunt!(pm_data::Dict, pwf_data::Dict; add_control_data::Bool=false)
    # Assumption - the reactive generation is already considering the number of unities
    if haskey(pwf_data, "DCER")

        for (i,shunt) in pwf_data["DCER"]
            _pwf2pm_DCER_shunt!(pm_data, pwf_data, shunt, add_control_data = add_control_data)
        end
    end
end

function _pwf2pm_DBAR_shunt!(pm_data::Dict, pwf_data::Dict, bus::Dict; add_control_data::Bool=false)
    sub_data = Dict{String,Any}()

    sub_data["shunt_bus"] = bus["NUMBER"]
    sub_data["gs"] = 0.0        
    sub_data["bs"] =  bus["TOTAL REACTIVE POWER"] 

    if bus["STATUS"] == 'L'
        sub_data["status"] = 1
    elseif bus["STATUS"] == 'D'
        sub_data["status"] = 0
    end    

    if add_control_data
        sub_data["control_data"] = Dict{String,Any}()

        sub_data["control_data"]["section"] = "DBAR"
        

        sub_data["control_data"]["shunt_type"] = 1
        sub_data["control_data"]["shunt_control_type"] = 1
        
        sub_data["control_data"]["bsmin"] = sub_data["bs"]
        sub_data["control_data"]["bsmax"] = sub_data["bs"]
        @assert sub_data["control_data"]["bsmin"] <= sub_data["control_data"]["bsmax"]

        sub_data["control_data"]["vmmin"] = bus["VOLTAGE"]
        sub_data["control_data"]["vmmax"] = bus["VOLTAGE"]
        sub_data["control_data"]["controlled_bus"] = bus["CONTROLLED BUS"]
        sub_data["control_data"]["inclination"] = nothing
    end

    n = count(x -> x["shunt_bus"] == sub_data["shunt_bus"], values(pm_data["shunt"])) 
    sub_data["source_id"] = ["fixed shunt", sub_data["shunt_bus"], "0$(n+1)"]
    sub_data["index"] = length(pm_data["shunt"]) + 1

    idx = string(sub_data["index"])
    pm_data["shunt"][idx] = sub_data
end

function _pwf2pm_DBAR_shunt!(pm_data::Dict, pwf_data::Dict; add_control_data::Bool=false)
     # fixed shunts specified at DBAR
     fixed_shunt_bus = findall(x -> x["TOTAL REACTIVE POWER"] != 0.0, pwf_data["DBAR"])

     for bus in fixed_shunt_bus
        _pwf2pm_DBAR_shunt!(pm_data, pwf_data, pwf_data["DBAR"][bus], add_control_data = add_control_data)
     end 
end

function _pwf2pm_shunt!(pm_data::Dict, pwf_data::Dict; add_control_data::Bool=false)
    pm_data["shunt"] = Dict{String, Any}()

    _pwf2pm_DBAR_shunt!(pm_data, pwf_data, add_control_data = add_control_data)
   
    _pwf2pm_DCER_shunt!(pm_data, pwf_data, add_control_data = add_control_data)

    _pwf2pm_DBSH_shunt!(pm_data, pwf_data, add_control_data = add_control_data)
end