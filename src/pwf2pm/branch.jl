# Analyzing PowerModels' raw parser, it was concluded that b_to & b_fr data was present in DSHL section
function _handle_b(pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64, circuit::Int, dict_dshl)
    b_fr, b_to = susceptance / 200, susceptance / 200
    if haskey(pwf_data, "DSHL") && haskey(dict_dshl, (f_bus, t_bus)) && haskey(dict_dshl[(f_bus, t_bus)], circuit)
        group = dict_dshl[(f_bus, t_bus)][circuit]
        b_fr += group["SHUNT FROM"] !== nothing && group["STATUS FROM"] == " L" ? group["SHUNT FROM"] / 100 : 0
        b_to += group["SHUNT TO"] !== nothing && group["STATUS TO"] == " L" ? group["SHUNT TO"] / 100 : 0
    end
    return b_fr, b_to
end

function _create_dict_dshl(data::Dict)
    dshl_dict = Dict{Tuple, Any}()

    for (k,v) in data
        sub_data = Dict{String, Any}()
        sub_data["SHUNT FROM"] = v["SHUNT FROM"]
        sub_data["SHUNT TO"] = v["SHUNT TO"]
        sub_data["STATUS FROM"] = v["STATUS FROM"]
        sub_data["STATUS TO"] = v["STATUS TO"]
        current_value = get(dshl_dict, (v["FROM BUS"], v["TO BUS"]), Dict{Int, Any}())
        current_value[v["CIRCUIT"]] = sub_data
        dshl_dict[(v["FROM BUS"], v["TO BUS"])] = current_value
    end
    return dshl_dict
end

function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict, branch::Dict)
    sub_data = Dict{String,Any}()

    sub_data["f_bus"] = pop!(branch, "FROM BUS")
    sub_data["t_bus"] = pop!(branch, "TO BUS")
    sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
    sub_data["br_x"] = pop!(branch, "REACTANCE") / 100

    dshl_dict = haskey(pwf_data, "DSHL") ? _create_dict_dshl(pwf_data["DSHL"]) : nothing
    b = _handle_b(pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"], branch["CIRCUIT"], dshl_dict)
    sub_data["g_fr"] = 0.0
    sub_data["b_fr"] = b[1]
    sub_data["g_to"] = 0.0
    sub_data["b_to"] = b[2]

    sub_data["tap"] = pop!(branch, "TAP")
    sub_data["tapmin"] = sub_data["tap"]
    sub_data["tapmax"] = sub_data["tap"]
    sub_data["shift"] = -pop!(branch, "LAG")
    sub_data["angmin"] = -360.0 # No limit
    sub_data["angmax"] = 360.0 # No limit
    sub_data["transformer"] = false

    if branch["STATUS"] == branch["OPENING FROM BUS"] == branch["OPENING TO BUS"] == 'L'
        sub_data["br_status"] = 1
    else
        sub_data["br_status"] = 0
    end

    sub_data["circuit"] = branch["CIRCUIT"]
    sub_data["source_id"] = ["branch", sub_data["f_bus"], sub_data["t_bus"], "01"]
    sub_data["index"] = length(pm_data["branch"]) + 1

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

    idx = string(sub_data["index"])
    pm_data["branch"][idx] = sub_data

end

function _pwf2pm_DCSC_branch!(pm_data::Dict, pwf_data::Dict, branch::Dict)
    sub_data = Dict{String,Any}()

    sub_data["f_bus"] = pop!(branch, "FROM BUS")
    sub_data["t_bus"] = pop!(branch, "TO BUS")
    sub_data["br_r"] = 0
    sub_data["br_x"] = pop!(branch, "INITIAL VALUE") / 100

    sub_data["g_fr"] = 0.0
    sub_data["b_fr"] = 0.0
    sub_data["g_to"] = 0.0
    sub_data["b_to"] = 0.0

    sub_data["tap"] = 1.0
    sub_data["tapmin"] = 1.0
    sub_data["tapmax"] = 1.0
    sub_data["shift"] = 0
    sub_data["angmin"] = -360.0
    sub_data["angmax"] = 360.0
    sub_data["transformer"] = false

    if branch["STATUS"] == 'L'
        sub_data["br_status"] = 1
    else
        sub_data["br_status"] = 0
    end

    sub_data["circuit"] = branch["CIRCUIT"]
    sub_data["source_id"] = ["branch", sub_data["f_bus"], sub_data["t_bus"], "01"]
    sub_data["index"] = length(pm_data["branch"]) + 1

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

    rep = findall(x -> x["f_bus"] == sub_data["f_bus"] && x["t_bus"] == sub_data["t_bus"] && x["circuit"] == sub_data["circuit"], pm_data["branch"])
    if length(rep) > 0
        @warn "Branch from $(sub_data["f_bus"]) to $(sub_data["t_bus"]) in circuit $(sub_data["circuit"]) is duplicated"
    end
    idx = string(sub_data["index"])
    pm_data["branch"][idx] = sub_data

end

function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict)
    pm_data["branch"] = Dict{String, Any}()
    if haskey(pwf_data, "DLIN")
        for (i,branch) in pwf_data["DLIN"]
            if !branch["TRANSFORMER"]
                _pwf2pm_branch!(pm_data, pwf_data, branch)
            end
        end
    end
    if haskey(pwf_data, "DCSC")
        for (i,csc) in pwf_data["DCSC"]
            _pwf2pm_DCSC_branch!(pm_data, pwf_data, csc)
        end
    end
end
