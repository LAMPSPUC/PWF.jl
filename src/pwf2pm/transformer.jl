function _handle_base_mva(pwf_data::Dict)
    baseMVA = 100.0 # Default value for this field in .pwf
    if haskey(pwf_data, "DCTE")
        if haskey(pwf_data["DCTE"], "BASE")
            baseMVA = pwf_data["DCTE"]["BASE"]
        end
    end
    return baseMVA
end

function _pwf2pm_transformer!(pm_data::Dict, pwf_data::Dict, branch::Dict) # Two-winding transformer
    sub_data = Dict{String,Any}()

    sub_data["f_bus"] = pop!(branch, "FROM BUS")
    sub_data["t_bus"] = pop!(branch, "TO BUS")
    sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
    sub_data["br_x"] = pop!(branch, "REACTANCE") / 100
    sub_data["g_fr"] = 0.0
    sub_data["g_to"] = 0.0
    sub_data["tap"] = pop!(branch, "TAP")
    sub_data["shift"] = -pop!(branch, "LAG")
    sub_data["angmin"] = -60.0
    sub_data["angmax"] = 60.0
    sub_data["transformer"] = true

    if branch["STATUS"] == branch["OPENING FROM BUS"] == branch["OPENING TO BUS"] == 'L'
        sub_data["br_status"] = 1
    else
        sub_data["br_status"] = 0
    end

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

    sub_data["control_info"] = Dict{String,Any}()
    sub_data["control_info"]["tapmin"] = pop!(branch, "MINIMUM TAP")
    sub_data["control_info"]["tapmax"] = pop!(branch, "MAXIMUM TAP")
    sub_data["control_info"]["circuit"] = branch["CIRCUIT"]
    sub_data["control_info"]["type"] = sub_data["control_info"]["tapmin"] == sub_data["control_info"]["tapmax"] ? "fixed tap" : "variable tap"
    ctrl_bus = pm_data["bus"]["$(abs(branch["CONTROLLED BUS"]))"]
    sub_data["control_info"]["vsp"] = ctrl_bus["vm"]
    sub_data["control_info"]["vmin"] = ctrl_bus["vmin"]
    sub_data["control_info"]["vmax"] = ctrl_bus["vmax"]
    sub_data["control_info"]["control"] =  false 
    if haskey(pwf_data, "DTPF CIRC")
        for (k,v) in pwf_data["DTPF CIRC"]
            for i in 1:5
                if v["FROM BUS $i"] == sub_data["f_bus"] && v["TO BUS $i"] == sub_data["t_bus"]
                    sub_data["control_info"]["control"] = true
                end
            end
        end
    end

    idx = string(sub_data["index"])
    pm_data["branch"][idx] = sub_data
end

function _pwf2pm_transformer!(pm_data::Dict, pwf_data::Dict) # Two-winding transformer
    if !haskey(pm_data, "branch")
        pm_data["branch"] = Dict{String, Any}()
    end

    if haskey(pwf_data, "DLIN")
        for (i,branch) in pwf_data["DLIN"]
            if branch["TRANSFORMER"]
                _pwf2pm_transformer!(pm_data, pwf_data, branch)
            end
        end
    end
end
