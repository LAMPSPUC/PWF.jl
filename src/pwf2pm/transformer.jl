function _handle_base_mva(pwf_data::Dict)
    baseMVA = 100.0 # Default value for this field in .pwf
    if haskey(pwf_data, "DCTE")
        if haskey(pwf_data["DCTE"], "BASE")
            baseMVA = pwf_data["DCTE"]["BASE"]
        end
    end
    return baseMVA
end

function _create_dict_dctr(data::Dict)
    dctr_dict = Dict{Tuple, Any}()

    for (k,v) in data
        sub_data = Dict{String, Any}()

        voltage_control = haskey(v, "VOLTAGE CONTROL") ? v["VOLTAGE CONTROL"] : true
        phase_control = haskey(v, "PHASE CONTROL") ? v["PHASE CONTROL"] : true
        if voltage_control && !phase_control
            sub_data["TYPE OF CONTROL"] = "VOLTAGE CONTROL"
            sub_data["MINIMUM VOLTAGE"] = v["MINIMUM VOLTAGE"]
            sub_data["MAXIMUM VOLTAGE"] = v["MAXIMUM VOLTAGE"]
            sub_data["SPECIFIED VALUE"] = v["SPECIFIED VALUE"]
            sub_data["MEASUREMENT EXTREMITY"] = v["MEASUREMENT EXTREMITY"]
        elseif phase_control && !voltage_control
            sub_data["TYPE OF CONTROL"] = "PHASE CONTROL"
            sub_data["MINIMUM PHASE"] = v["MINIMUM PHASE"]
            sub_data["MAXIMUM PHASE"] = v["MAXIMUM PHASE"]
            sub_data["SPECIFIED VALUE"] = v["SPECIFIED VALUE"]
            sub_data["MEASUREMENT EXTREMITY"] = v["MEASUREMENT EXTREMITY"]
            sub_data["CONTROL TYPE"] = v["CONTROL TYPE"]
        else
            @error("DCTR data should refer either to voltage or phase control")
        end
        current_value = get(dctr_dict, (v["FROM BUS"], v["TO BUS"]), Dict{Int, Any}())
        current_value[v["CIRCUIT"]] = sub_data
        dctr_dict[(v["FROM BUS"], v["TO BUS"])] = current_value
    end
    return dctr_dict
end

function _pwf2pm_transformer!(pm_data::Dict, pwf_data::Dict, branch::Dict; add_control_data::Bool=false) # Two-winding transformer
    sub_data = Dict{String,Any}()

    sub_data["f_bus"] = pop!(branch, "FROM BUS")
    sub_data["t_bus"] = pop!(branch, "TO BUS")
    sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
    sub_data["br_x"] = pop!(branch, "REACTANCE") / 100
    sub_data["g_fr"] = 0.0
    sub_data["g_to"] = 0.0
    sub_data["tap"] = pop!(branch, "TAP")
    sub_data["shift"] = -pop!(branch, "LAG")
    sub_data["angmin"] = -60.0 # PowerModels.jl standard
    sub_data["angmax"] = 60.0 # PowerModels.jl standard
    sub_data["transformer"] = true

    _handle_br_status!(pm_data, sub_data, branch)

    n = 0 # count(x -> x["f_bus"] == sub_data["f_bus"] && x["t_bus"] == sub_data["t_bus"], values(pm_data["branch"])) 
    sub_data["source_id"] = ["transformer", sub_data["f_bus"], sub_data["t_bus"], 0, "0$(n + 1)", 0]
    sub_data["index"] = length(pm_data["branch"]) + 1

    dict_dshl = haskey(pwf_data, "DSHL") ? _create_dict_dshl(pwf_data["DSHL"]) : nothing
    b = _handle_b(pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"], branch["CIRCUIT"], dict_dshl)
    sub_data["b_fr"] = b[1]
    sub_data["b_to"] = b[2]

    sub_data["rate_a"] = pop!(branch, "NORMAL CAPACITY")
    sub_data["rate_b"] = pop!(branch, "EMERGENCY CAPACITY")
    sub_data["rate_c"] = pop!(branch, "EQUIPAMENT CAPACITY")

    if sub_data["rate_a"] >= 9999
        delete!(sub_data, "rate_a")
    end
    if sub_data["rate_b"] >= 9999
        delete!(sub_data, "rate_b")
    end
    if sub_data["rate_c"] >= 9999
        delete!(sub_data, "rate_c")
    end

    if add_control_data
        sub_data["control_data"] = Dict{String,Any}()
        sub_data["control_data"]["tapmin"] = pop!(branch, "MINIMUM TAP")
        sub_data["control_data"]["tapmax"] = pop!(branch, "MAXIMUM TAP")
        sub_data["control_data"]["circuit"] = branch["CIRCUIT"]

        sub_data["control_data"]["controlled_bus"] = abs(branch["CONTROLLED BUS"])

        dict_dctr = haskey(pwf_data, "DCTR") ? _create_dict_dctr(pwf_data["DCTR"]) : nothing
        constraint_type = "fix"
        if isa(dict_dctr, Dict) && haskey(dict_dctr, (sub_data["f_bus"], sub_data["t_bus"]))
            branch_dctr = dict_dctr[(sub_data["f_bus"], sub_data["t_bus"])]
            circuit = branch["CIRCUIT"]
            if haskey(branch_dctr, circuit)
                constraint_type = branch_dctr[circuit]["TYPE OF CONTROL"]
            end
        end

        tap_bounds = sub_data["control_data"]["tapmin"] !== nothing && sub_data["control_data"]["tapmax"] !== nothing
        if tap_bounds # tap control
            sub_data["control_data"]["control_type"] = "tap_control"
            sub_data["control_data"]["shift_control_variable"] = nothing
            sub_data["control_data"]["shiftmin"] = nothing
            sub_data["control_data"]["shiftmax"] = nothing

            if constraint_type == "VOLTAGE CONTROL"

                sub_data["control_data"]["constraint_type"] = "bounds"
                sub_data["control_data"]["valsp"] = branch_dctr[circuit]["SPECIFIED VALUE"]
                sub_data["control_data"]["controlled_bus"] = branch_dctr[circuit]["MEASUREMENT EXTREMITY"]

                pm_data["bus"]["$(sub_data["control_data"]["controlled_bus"])"]["control_data"]["control_type"] = "tap_control"
                if isnothing(pm_data["bus"]["$(sub_data["control_data"]["controlled_bus"])"]["control_data"]["constraint_type"]) # setpoint is more restrict than bounds
                    pm_data["bus"]["$(sub_data["control_data"]["controlled_bus"])"]["control_data"]["constraint_type"] = "bounds"
                end
        
            else
                pm_data["bus"]["$(sub_data["control_data"]["controlled_bus"])"]["control_data"]["control_type"] = "tap_control"

                sub_data["control_data"]["constraint_type"] = "setpoint"
                sub_data["control_data"]["valsp"] = nothing
                pm_data["bus"]["$(sub_data["control_data"]["controlled_bus"])"]["control_data"]["constraint_type"] = "setpoint"
            end

        elseif constraint_type == "PHASE CONTROL" # phase control
            sub_data["control_data"]["control_type"] = "shift_control"
            sub_data["control_data"]["constraint_type"] = "setpoint"
            shift_type = branch_dctr[circuit]["CONTROL TYPE"]
            sub_data["control_data"]["shift_control_variable"] = shift_type == 'C' ? "current" : shift_type == 'P' ? "power" : "fixed"
            sub_data["control_data"]["shiftmin"] = branch_dctr[circuit]["MINIMUM PHASE"] / (180/pi)
            sub_data["control_data"]["shiftmax"] = branch_dctr[circuit]["MAXIMUM PHASE"] / (180/pi)
            sub_data["control_data"]["valsp"] = branch_dctr[circuit]["SPECIFIED VALUE"] / 100
    
            sub_data["control_data"]["controlled_bus"] = branch_dctr[circuit]["MEASUREMENT EXTREMITY"]
    
        else # fix
            sub_data["control_data"]["control_type"] = "fix"
            sub_data["control_data"]["constraint_type"] = nothing
            sub_data["control_data"]["shift_control_variable"] = nothing
            sub_data["control_data"]["shiftmin"] = nothing
            sub_data["control_data"]["shiftmax"] = nothing
            sub_data["control_data"]["valsp"] = nothing
        end

        ctrl_bus = pm_data["bus"]["$(sub_data["control_data"]["controlled_bus"])"]
        sub_data["control_data"]["vmsp"] = ctrl_bus["vm"]
        sub_data["control_data"]["vmmin"] = ctrl_bus["vmin"]
        sub_data["control_data"]["vmmax"] = ctrl_bus["vmax"]
        sub_data["control_data"]["control"] =  true 
        if haskey(pwf_data, "DTPF CIRC")
            for (k,v) in pwf_data["DTPF CIRC"]
                for i in 1:5
                    if v["FROM BUS $i"] == sub_data["f_bus"] && v["TO BUS $i"] == sub_data["t_bus"] && v["CIRCUIT $i"] == branch["CIRCUIT"]
                        sub_data["control_data"]["control"] = false
                    end
                end
            end
        end
    end
    idx = string(sub_data["index"])
    pm_data["branch"][idx] = sub_data
end

function _pwf2pm_transformer!(pm_data::Dict, pwf_data::Dict; add_control_data::Bool=false) # Two-winding transformer
    if !haskey(pm_data, "branch")
        pm_data["branch"] = Dict{String, Any}()
    end

    if haskey(pwf_data, "DLIN")
        for (i,branch) in pwf_data["DLIN"]
            if branch["TRANSFORMER"]
                _pwf2pm_transformer!(pm_data, pwf_data, branch, add_control_data = add_control_data)
            end
        end
    end
end
