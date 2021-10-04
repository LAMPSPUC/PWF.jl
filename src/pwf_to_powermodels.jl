#################################################################
#                                                               #
#    This file provides functions for converting .pwf into      #
#              PowerModels.jl data structure                    #
#                                                               #
#################################################################

# This parser was develop using ANAREDE v09' user manual and PSSE 
# .raw manual for references.

# This converter uses Organon HPPA raw - pwf converter as benchmark 

const bus_type_num_to_str    = Dict(1 => "PQ", 2 => "PV", 3 => "Vθ", 4 => "OFF")
const bus_type_str_to_num    = Dict("PQ" => 1, "PV" => 2, "Vθ" => 3, "OFF" => 4)
const bus_type_pwf_to_raw    = Dict(0 => 1, 1 => 2, 2 => 3, 3 => 1)
const bus_type_raw_to_pwf    = Dict(1 => 0, 2 => 1, 3 => 2)
const element_status         = Dict(0 => "OFF", "D" => "OFF", 1 => "ON", "L" => "ON")

function _handle_base_kv(pwf_data::Dict, bus::Dict, dict_dgbt)
    group_identifier = bus["BASE VOLTAGE GROUP"]
    if haskey(pwf_data, "DGBT")
        if length(pwf_data["DGBT"]) == 1 && pwf_data["DGBT"]["1"]["GROUP"] != group_identifier
            @warn "Only one base voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGBT"]["1"]["GROUP"])"
            return pwf_data["DGBT"]["1"]["VOLTAGE"]
        else
            group = dict_dgbt[group_identifier]
            @assert length(group) == 1
            return group["VOLTAGE"]
        end
    else
        return 1.0 # Default value for this field in .pwf
    end
end

function _handle_vmin(pwf_data::Dict, bus::Dict, dict_dglt)
    group_identifier = bus["VOLTAGE LIMIT GROUP"]
    if haskey(pwf_data, "DGLT") 
        group = dict_dglt[group_identifier]
        if length(group) == 1
            return group["LOWER BOUND"]
        elseif length(pwf_data["DGLT"]) == 1
            @warn "Only one limit voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGLT"]["1"]["GROUP"])"
            return pwf_data["DGLT"]["1"]["LOWER BOUND"]
        end
    end
    return 0.9 # Default value given in the PSS(R)E specification    
end

function _handle_vmax(pwf_data::Dict, bus::Dict, dict_dglt)
    group_identifier = bus["VOLTAGE LIMIT GROUP"] 
    if haskey(pwf_data, "DGLT") 
        group = dict_dglt[group_identifier]
        if length(group) == 1
            return group["UPPER BOUND"]
        elseif length(pwf_data["DGLT"]) == 1
            @warn "Only one limit voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGLT"]["1"]["GROUP"])"
            return pwf_data["DGLT"]["1"]["UPPER BOUND"]
        end
    end
    return 1.1 # Default value given in the PSS(R)E specification    
end

function _handle_bus_type(bus::Dict)
    bus_type = bus["TYPE"]
    dict_bus_type = Dict(0 => 1, 3 => 1, # PQ
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

function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict, bus::Dict)
    sub_data = Dict{String,Any}()

    sub_data["bus_i"] = bus["NUMBER"]
    sub_data["bus_type"] = _handle_bus_type(bus)
    sub_data["area"] = pop!(bus, "AREA")
    sub_data["vm"] = bus["VOLTAGE"]/1000 # Implicit decimal point ignored
    sub_data["va"] = pop!(bus, "ANGLE")
    sub_data["zone"] = 1
    sub_data["name"] = pop!(bus, "NAME")

    sub_data["source_id"] = ["bus", "$(bus["NUMBER"])"]
    sub_data["index"] = bus["NUMBER"]

    dict_dglt = haskey(pwf_data, "DGLT") ? _create_dict_dglt(pwf_data["DGLT"]) : nothing
    dict_dgbt = haskey(pwf_data, "DGLT") ? _create_dict_dgbt(pwf_data["DGBT"]) : nothing
    sub_data["base_kv"] = _handle_base_kv(pwf_data, bus, dict_dgbt)
    sub_data["vmin"] = _handle_vmin(pwf_data, bus, dict_dglt)
    sub_data["vmax"] = _handle_vmax(pwf_data, bus, dict_dglt)

    sub_data["voltage_controlled_bus"] = pop!(bus, "CONTROLLED BUS")

    idx = string(sub_data["index"])
    pm_data["bus"][idx] = sub_data
end

function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict)

    pm_data["bus"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for (i,bus) in pwf_data["DBAR"]
            _pwf2pm_bus!(pm_data, pwf_data, bus)
        end
    end
end

function _create_dict_dshl(data::Dict)
    dshl_dict = Dict{Tuple, Any}()

    for (k,v) in data
        sub_data = Dict{String, Any}()
        sub_data["SHUNT FROM"] = v["SHUNT FROM"]
        sub_data["SHUNT TO"] = v["SHUNT TO"]
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
    sub_data["g_fr"] = 0.0
    sub_data["b_fr"] = _handle_b_fr(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"], branch["CIRCUIT"], dshl_dict)
    sub_data["g_to"] = 0.0
    sub_data["b_to"] = _handle_b_to(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"], branch["CIRCUIT"], dshl_dict)

    sub_data["tap"] = pop!(branch, "TAP")
    sub_data["shift"] = -pop!(branch, "LAG")
    sub_data["angmin"] = -360.0 # No limit
    sub_data["angmax"] = 360.0 # No limit
    sub_data["transformer"] = false

    if branch["STATUS"] == 'D'
        sub_data["br_status"] = 0
    else
        sub_data["br_status"] = 1
    end

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

function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict)

    pm_data["branch"] = Dict{String, Any}()
    if haskey(pwf_data, "DLIN")
        for (i,branch) in pwf_data["DLIN"]
            if !branch["TRANSFORMER"]
                _pwf2pm_branch!(pm_data, pwf_data, branch)
            end
        end
    end
end

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

function _handle_base_mva(pwf_data::Dict)
    baseMVA = 100.0 # Default value for this field in .pwf
    if haskey(pwf_data, "DCTE")
        if haskey(pwf_data["DCTE"], "BASE")
            baseMVA = pwf_data["DCTE"]["BASE"]
        end
    end
    return baseMVA
end

# Analyzing PowerModels' raw parser, it was concluded that b_to & b_fr data was present in DSHL section
function _handle_b_fr(pm_data::Dict, pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64, circuit::Int, dict_dshl)
    b_fr = susceptance / 2.0
    if haskey(pwf_data, "DSHL")
        if haskey(dict_dshl, (f_bus, t_bus))
            if haskey(dict_dshl[(f_bus, t_bus)], circuit)
                group = dict_dshl[(f_bus, t_bus)][circuit]
                if group["SHUNT FROM"] !== nothing
                    b_fr = group["SHUNT FROM"] / 100
                end
            end
        end
    end
    return b_fr / 100
end

function _handle_b_to(pm_data, pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64, circuit::Int, dict_dshl)
    b_to = susceptance / 2.0
    if haskey(pwf_data, "DSHL")
        if haskey(dict_dshl, (f_bus, t_bus))
            if haskey(dict_dshl[(f_bus, t_bus)], circuit)
                group = dict_dshl[(f_bus, t_bus)][circuit]
                if group["SHUNT TO"] !== nothing
                    b_to = group["SHUNT TO"] / 100
                end
            end
        end
    end
    return b_to / 100
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
    sub_data["angmin"] = -360.0 # No limit
    sub_data["angmax"] = 360.0 # No limit
    sub_data["transformer"] = true

    if branch["STATUS"] == 'D'
        sub_data["br_status"] = 0
    else
        sub_data["br_status"] = 1
    end

    n = 0 # count(x -> x["f_bus"] == sub_data["f_bus"] && x["t_bus"] == sub_data["t_bus"], values(pm_data["branch"])) 
    sub_data["source_id"] = ["transformer", sub_data["f_bus"], sub_data["t_bus"], 0, "0$(n + 1)", 0]
    sub_data["index"] = length(pm_data["branch"]) + 1

    dict_dshl = haskey(pwf_data, "DSHL") ? _create_dict_dshl(pwf_data["DSHL"]) : nothing
    sub_data["b_fr"] = _handle_b_fr(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"], branch["CIRCUIT"], dict_dshl)
    sub_data["b_to"] = _handle_b_to(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"], branch["CIRCUIT"], dict_dshl)

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

function _handle_bs(shunt::Dict{String, Any})
    bs = 0
    for (i,el) in shunt["REACTANCE GROUPS"]
        if el["STATUS"] == 'L'
            bs += el["OPERATING UNITIES"]*el["REACTANCE"]
        end
    end
    return bs
end

function _pwf2pm_dcline!(pm_data::Dict, pwf_data::Dict, i1::Int)
    i2 = 2*(i1 - 1) + 1, 2*i1
    i4 = 4*(i1 - 1) + 1, 4*(i1 - 1) + 2, 4*(i1 - 1) + 3, 4*i1 

    sub_data = Dict{String, Any}()

    @assert pwf_data["DCCV"]["$(i2[1])"]["CONVERTER CONTROL TYPE"] == pwf_data["DCCV"]["$(i2[2])"]["CONVERTER CONTROL TYPE"]
    mdc  = pwf_data["DCCV"]["$(i2[1])"]["CONVERTER CONTROL TYPE"]

    setvl = pwf_data["DCCV"]["$(i2[1])"]["SPECIFIED VALUE"]
    vschd = pwf_data["DCBA"]["$(i4[1])"]["VOLTAGE"]
    power_demand = mdc == 'P' ? abs(setvl) : mdc == 'C' ? abs(setvl / vschd / 1000) : 0

    sub_data["f_bus"] = pwf_data["DCNV"]["$(i2[1])"]["AC BUS"]
    sub_data["t_bus"] = pwf_data["DCNV"]["$(i2[2])"]["AC BUS"]

    # Assumption - bus status is defined on DELO section
    sub_data["br_status"] = pwf_data["DELO"]["$i1"]["STATUS"] == 'L' ? 1 : 0

    sub_data["pf"] = power_demand
    sub_data["pt"] = power_demand
    sub_data["qf"] = 0.0
    sub_data["qt"] = 0.0

    # Assumption - vf & vt are directly the voltage for each bus, instead of what is indicated in DELO section
    bus_f = pwf_data["DBAR"]["$(sub_data["f_bus"])"]
    bus_t = pwf_data["DBAR"]["$(sub_data["t_bus"])"]
    sub_data["vf"] = bus_f["VOLTAGE"]/1000
    sub_data["vt"] = bus_t["VOLTAGE"]/1000

    # Assumption - the power demand sign is derived from the field looseness
    sub_data["pmaxf"] = pwf_data["DCCV"]["$(i2[1])"]["LOOSENESS"] == 'N' ? power_demand : -power_demand
    sub_data["pmint"] = pwf_data["DCCV"]["$(i2[1])"]["LOOSENESS"] == 'N' ? -power_demand : power_demand

    sub_data["pminf"] = 0.0
    sub_data["pmaxt"] = 0.0

    anmn = []
    for idx in i2
        angle = pwf_data["DCCV"]["$idx"]["MINIMUM CONVERTER ANGLE"]
        if abs(angle) <= 90.0
            push!(anmn, angle)
        else
            push!(anmn, 0)
            @warn("$key outside reasonable limits, setting to 0 degress")
        end
    end

    sub_data["qmaxf"] = 0.0
    sub_data["qmaxt"] = 0.0
    sub_data["qminf"] = -max(abs(sub_data["pminf"]), abs(sub_data["pmaxf"])) * cosd(anmn[1])
    sub_data["qmint"] = -max(abs(sub_data["pmint"]), abs(sub_data["pmaxt"])) * cosd(anmn[2])

    # Assumption - same values as PowerModels
    sub_data["loss0"] = 0.0
    sub_data["loss1"] = 0.0

    # Assumption - same values as PowerModels
    sub_data["startup"] = 0.0
    sub_data["shutdown"] = 0.0
    sub_data["ncost"] = 3
    sub_data["cost"] = [0.0, 0.0, 0.0]
    sub_data["model"] = 2

    sub_data["source_id"] = ["two-terminal dc", sub_data["f_bus"], sub_data["t_bus"], pwf_data["DCBA"]["$(i4[1])"]["NAME"]]
    sub_data["index"] = i1

    pm_data["dcline"]["$i1"] = sub_data
end

function _pwf2pm_dcline!(pm_data::Dict, pwf_data::Dict)

    pm_data["dcline"] = Dict{String, Any}()

    if !(haskey(pwf_data, "DCBA") && haskey(pwf_data, "DCLI") && haskey(pwf_data, "DCNV") && haskey(pwf_data, "DCCV") && haskey(pwf_data, "DELO"))
        @warn("DC line will not be parsed due to the absence of at least one those sections: DCBA, DCLI, DCNV, DCCV, DELO")
        return
    end
    @assert length(pwf_data["DCBA"]) == 4*length(pwf_data["DCLI"]) == 2*length(pwf_data["DCNV"]) == 2*length(pwf_data["DCCV"]) == 4*length(pwf_data["DELO"])

    for i1 in 1:length(pwf_data["DCLI"])
        _pwf2pm_dcline!(pm_data, pwf_data, i1)
    end
end

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

function _pwf2pm_fixed_shunt!(pm_data::Dict, pwf_data::Dict, bus::Dict)
    sub_data = Dict{String,Any}()

    sub_data["shunt_bus"] = bus["NUMBER"]
    sub_data["gs"] = 0.0        
    sub_data["bs"] =  bus["TOTAL REACTIVE POWER"] 

    sub_data["shunt_type"] = 1
    sub_data["shunt_type_orig"] = 1
    sub_data["bsmin"] = sub_data["bs"]
    sub_data["bsmax"] = sub_data["bs"]
    @assert sub_data["bsmin"] <= sub_data["bsmax"]

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

function _pwf2pm_continuous_shunt!(pm_data::Dict, pwf_data::Dict, shunt::Dict)
    n = count(x -> x["shunt_bus"] == shunt["BUS"], values(pm_data["shunt"])) 

    sub_data = Dict{String,Any}()

    sub_data["shunt_bus"] = shunt["BUS"]
    sub_data["gs"] = 0.0
    sub_data["bs"] = shunt["REACTIVE GENERATION"]

    sub_data["shunt_type"] = 2
    sub_data["shunt_type_orig"] = 2
    sub_data["bsmin"] = shunt["MINIMUM REACTIVE GENERATION"]
    sub_data["bsmax"] = shunt["MAXIMUM REACTIVE GENERATION"]
    @assert sub_data["bsmin"] <= sub_data["bsmax"]

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
    end
end

function _pwf2pm_discrete_shunt!(pm_data::Dict, pwf_data::Dict, shunt::Dict)
    # Assumption - shunt data should only consider devices without destination bus
    if shunt["TO BUS"] === nothing

        n = count(x -> x["shunt_bus"] == shunt["FROM BUS"], values(pm_data["shunt"])) 

        sub_data = Dict{String,Any}()

        sub_data["shunt_bus"] = shunt["FROM BUS"]
        sub_data["gs"] = 0.0
        
        sub_data["bs"] = _handle_bs(shunt)

        sub_data["shunt_type"] = shunt["CONTROL MODE"] == 'F' ? 1 : 2
        sub_data["shunt_type_orig"] = shunt["CONTROL MODE"] == 'F' ? 1 : 2
        bs_bounds = _handle_bs_bounds(shunt)
        sub_data["bsmin"] = bs_bounds[1]
        sub_data["bsmax"] = bs_bounds[2]
        @assert sub_data["bsmin"] <= sub_data["bsmax"]

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
        end
    end
end

# Assumption - if there are more than one shunt for the same bus we sum their values into one shunt (source: Organon)
# CAUTION: this might be an Organon error
function _pwf2pm_shunt!(pm_data::Dict, pwf_data::Dict)
    pm_data["shunt"] = Dict{String, Any}()

    fixed_shunt_bus = findall(x -> x["TOTAL REACTIVE POWER"] != 0.0, pwf_data["DBAR"])

    for bus in fixed_shunt_bus
        _pwf2pm_fixed_shunt!(pm_data, pwf_data, pwf_data["DBAR"][bus])
    end

    if haskey(pwf_data, "DCER") || haskey(pwf_data, "DBSH")
        @warn("PowerModels current version don't support non-fixed shunts. All continuous or discrete shunts (DCER or DBSH) are considered fixed.")
    end

    # Assumption - the reactive generation is already considering the number of unities
    if haskey(pwf_data, "DCER")

        for (i,shunt) in pwf_data["DCER"]
            _pwf2pm_continuous_shunt!(pm_data, pwf_data, shunt)
        end
    end

    if haskey(pwf_data, "DBSH")

        for (i,shunt) in pwf_data["DBSH"]
            _pwf2pm_discrete_shunt!(pm_data, pwf_data, shunt)
        end
    end
end

function generators_from_bus(pm_data::Dict, bus::Int; filters::Vector = [])
    filters = vcat(gen -> gen["gen_bus"] == bus, filters)
    return findall(
            x -> (
                all([f(x) for f in filters])
            ), 
            pm_data["gen"]
        )
end

function load_from_bus(pm_data::Dict, bus::Int; filters::Vector = [])
    filters = vcat(load -> load["load_bus"] == bus, filters)
    return findall(
            x -> (
                all([f(x) for f in filters])
            ), 
            pm_data["load"]
        )  
end

function _pwf2pm_corrections_PV!(pm_data::Dict, pwf_data::Dict)
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

function sum_generators_power_and_turn_off(pm_data::Dict, gen_keys::Vector)
    Pg = 0.0
    Qg = 0.0
    for (i, key) in enumerate(gen_keys)
        gen = pm_data["gen"][key]
        Pg += gen["pg"]
        Qg += gen["qg"]
        gen["gen_status"] = 0
    end
    return Pg, Qg
end

function _pwf2pm_corrections_PQ!(pm_data::Dict)
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

function _pwf2pm_corrections!(pm_data::Dict, pwf_data::Dict)
    _pwf2pm_corrections_PV!(pm_data, pwf_data)
    _pwf2pm_corrections_PQ!(pm_data)
    
    return 
end

function _correct_pwf_network_data(pm_data::Dict)
    mva_base = pm_data["baseMVA"]

    rescale        = x -> x/mva_base

    if haskey(pm_data, "shunt")
        for (i, shunt) in pm_data["shunt"]
            PowerModels._apply_func!(shunt, "bsmin", rescale)
            PowerModels._apply_func!(shunt, "bsmax", rescale)
        end
    end

end

function _parse_pwf_to_powermodels(pwf_data::Dict; validate::Bool=true)
    pm_data = Dict{String,Any}()

    pm_data["per_unit"] = false
    pm_data["source_type"] = "pwf"
    pm_data["source_version"] = "09"
    pm_data["name"] = pwf_data["name"]

    pm_data["baseMVA"] = _handle_base_mva(pwf_data)

    _pwf2pm_bus!(pm_data, pwf_data)
    _pwf2pm_branch!(pm_data, pwf_data)
    _pwf2pm_load!(pm_data, pwf_data)
    _pwf2pm_generator!(pm_data, pwf_data)
    _pwf2pm_transformer!(pm_data, pwf_data)
    _pwf2pm_dcline!(pm_data, pwf_data)
    _pwf2pm_shunt!(pm_data, pwf_data)
    # ToDo: fields not yet contemplated by the parser

    pm_data["storage"] = Dict{String,Any}()
    pm_data["switch"] = Dict{String,Any}()

    # Apply corrections in the pm_data accordingly to Organon
    _pwf2pm_corrections!(pm_data, pwf_data)

    if validate
        _correct_pwf_network_data(pm_data)
        PowerModels.correct_network_data!(pm_data)
    end
    
    return pm_data
end

"""
    parse_pwf_to_powermodels(filename::String, validate::Bool=false)::Dict

Parse .pwf file directly to PowerModels data structure
"""
function parse_pwf_to_powermodels(filename::String; validate::Bool=true)::Dict
    pwf_data = open(filename) do f
        parse_pwf(f)
    end

    # Parse Dict to a Power Models format
    pm = _parse_pwf_to_powermodels(pwf_data, validate = validate)
    return pm
end

"""
    parse_pwf_to_powermodels(io::Io, validate::Bool=false)::Dict

"""
function parse_pwf_to_powermodels(io::IO; validate::Bool=true)::Dict
    pwf_data = _parse_pwf_data(io)

    # Parse Dict to a Power Models format
    pm = _parse_pwf_to_powermodels(pwf_data, validate = validate)
    return pm
end
