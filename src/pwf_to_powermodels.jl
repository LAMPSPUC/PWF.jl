#################################################################
#                                                               #
#    This file provides functions for converting .pwf into      #
#              PowerModels.jl data structure                    #
#                                                               #
#################################################################

# This parser was develop using ANAREDE v09' user manual and PSSE 
# .raw manual for references.

# This converter uses Organon HPPA raw - pwf converter as benchmark 

function _handle_base_kv(pwf_data::Dict, bus::Dict)
    group_identifier = bus["BASE VOLTAGE GROUP"]
    if haskey(pwf_data, "DGBT")
        if length(pwf_data["DGBT"]) == 1 && pwf_data["DGBT"][1]["GROUP"] != group_identifier
            @warn "Only one base voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGBT"][1]["GROUP"])"
            return pwf_data["DGBT"][1]["VOLTAGE"]
        else
            group = filter(x -> x["GROUP"] == group_identifier, pwf_data["DGBT"])
            @assert length(group) == 1
            return group[1]["VOLTAGE"]
        end
    else
        return 1.0 # Default value for this field in .pwf
    end
end

function _handle_vmin(pwf_data::Dict, bus::Dict)
    group_identifier = bus["VOLTAGE LIMIT GROUP"]
    if haskey(pwf_data, "DGLT") 
        group = filter(x -> x["GROUP"] == group_identifier, pwf_data["DGLT"])
        if length(group) == 1
            return group[1]["LOWER BOUND"]
        elseif length(pwf_data["DGLT"]) == 1
            @warn "Only one limit voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGLT"][1]["GROUP"])"
            return pwf_data["DGLT"][1]["LOWER BOUND"]
        end
    end
    return 0.9 # Default value given in the PSS(R)E specification    
end

function _handle_vmax(pwf_data::Dict, bus::Dict)
    group_identifier = bus["VOLTAGE LIMIT GROUP"] 
    if haskey(pwf_data, "DGLT") 
        group = filter(x -> x["GROUP"] == group_identifier, pwf_data["DGLT"])
        if length(group) == 1
            return group[1]["UPPER BOUND"]
        elseif length(pwf_data["DGLT"]) == 1
            @warn "Only one limit voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGLT"][1]["GROUP"])"
            return pwf_data["DGLT"][1]["UPPER BOUND"]
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
function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict)

    pm_data["bus"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
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

            sub_data["base_kv"] = _handle_base_kv(pwf_data, bus)
            sub_data["vmin"] = _handle_vmin(pwf_data, bus)
            sub_data["vmax"] = _handle_vmax(pwf_data, bus)

            idx = string(sub_data["index"])
            pm_data["bus"][idx] = sub_data
        end
    end
end


function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict)

    pm_data["branch"] = Dict{String, Any}()
    if haskey(pwf_data, "DLIN")
        for branch in pwf_data["DLIN"]
            if !branch["TRANSFORMER"]
                sub_data = Dict{String,Any}()

                sub_data["f_bus"] = pop!(branch, "FROM BUS")
                sub_data["t_bus"] = pop!(branch, "TO BUS")
                sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
                sub_data["br_x"] = pop!(branch, "REACTANCE") / 100
                sub_data["g_fr"] = 0.0
                sub_data["b_fr"] = _handle_b_fr(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])
                sub_data["g_to"] = 0.0
                sub_data["b_to"] = _handle_b_to(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])
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
        end
    end
end

function _pwf2pm_load!(pm_data::Dict, pwf_data::Dict)

    pm_data["load"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            if bus["ACTIVE CHARGE"] > 0.0 || bus["REACTIVE CHARGE"] > 0.0
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
        end
    end
end

function _handle_pmin(pwf_data::Dict, bus_i::Int)
    if haskey(pwf_data, "DGER")
        bus = filter(x -> x["NUMBER"] == bus_i, pwf_data["DGER"])
        if length(bus) == 1
            return bus[1]["MINIMUM ACTIVE GENERATION"]
        end
    end    
    @warn("DGER not found, setting pmin as the bar active generation")
    bus = findfirst(x -> x["NUMBER"] == bus_i, pwf_data["DBAR"])
    return pwf_data["DBAR"][bus]["ACTIVE GENERATION"]
end

function _handle_pmax(pwf_data::Dict, bus_i::Int)
    if haskey(pwf_data, "DGER")
        bus = filter(x -> x["NUMBER"] == bus_i, pwf_data["DGER"])
        if length(bus) == 1
            return bus[1]["MAXIMUM ACTIVE GENERATION"]
        end
    end
    @warn("DGER not found, setting pmax as the bar active generation")
    bus = findfirst(x -> x["NUMBER"] == bus_i, pwf_data["DBAR"])
    return pwf_data["DBAR"][bus]["ACTIVE GENERATION"]
end

function _pwf2pm_generator!(pm_data::Dict, pwf_data::Dict)

    pm_data["gen"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            if bus["TYPE"] == 1 || bus["TYPE"] == 2
                sub_data = Dict{String,Any}()

                sub_data["gen_bus"] = bus["NUMBER"]
                sub_data["gen_status"] = 1
                sub_data["pg"] = bus["ACTIVE GENERATION"]
                sub_data["qg"] = bus["REACTIVE GENERATION"]
                sub_data["vg"] = pm_data["bus"]["$(bus["NUMBER"])"]["vm"]
                sub_data["mbase"] = _handle_base_mva(pwf_data)
                sub_data["pmin"] = _handle_pmin(pwf_data, bus["NUMBER"])
                sub_data["pmax"] = _handle_pmax(pwf_data, bus["NUMBER"])
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

function _pwf2pm_transformer!(pm_data::Dict, pwf_data::Dict) # Two-winding transformer
    if !haskey(pm_data, "branch")
        pm_data["branch"] = Dict{String, Any}()
        non_transformers = 0
    else
        non_transformers = length(pm_data["branch"])
    end

    if haskey(pwf_data, "DLIN")
        for branch in pwf_data["DLIN"]
            if branch["TRANSFORMER"]
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

                n = count(x -> x["f_bus"] == sub_data["f_bus"] && x["t_bus"] == sub_data["t_bus"], values(pm_data["branch"])) 
                sub_data["source_id"] = ["transformer", sub_data["f_bus"], sub_data["t_bus"], 0, "0$(n + 1)", 0]
                sub_data["index"] = length(pm_data["branch"]) + 1

                sub_data["b_fr"] = _handle_b_fr(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])
                sub_data["b_to"] = _handle_b_to(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])

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
        end
    end
end

# Analyzing PowerModels' raw parser, it was concluded that b_to & b_fr data was present in DSHL section
function _handle_b_fr(pm_data::Dict, pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64)
    i = count(x -> x["f_bus"] == f_bus && x["t_bus"] == t_bus, values(pm_data["branch"])) + 1
    b_fr = susceptance / 2.0
    if haskey(pwf_data, "DSHL")
        group = findall(x -> x["FROM BUS"] == f_bus && x["TO BUS"] == t_bus, pwf_data["DSHL"])
        if length(group) > 0 && length(group) >= i
            if pwf_data["DSHL"][group[i]]["SHUNT FROM"] !== nothing
                b_fr = pwf_data["DSHL"][group[i]]["SHUNT FROM"] / 100
            end
        end
    end
    return b_fr / 100
end

function _handle_b_to(pm_data, pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64)
    i = count(x -> x["f_bus"] == f_bus && x["t_bus"] == t_bus, values(pm_data["branch"])) + 1
    b_to = susceptance / 2.0
    if haskey(pwf_data, "DSHL")
        group = findall(x -> x["FROM BUS"] == f_bus && x["TO BUS"] == t_bus, pwf_data["DSHL"])
        if length(group) > 0 && length(group) >= i
            if pwf_data["DSHL"][group[i]]["SHUNT TO"] !== nothing
                b_to = pwf_data["DSHL"][group[i]]["SHUNT TO"] / 100
            end
        end
    end
    return b_to / 100
end

function _pwf2pm_dcline!(pm_data::Dict, pwf_data::Dict)

    pm_data["dcline"] = Dict{String, Any}()

    if !(haskey(pwf_data, "DCBA") && haskey(pwf_data, "DCLI") && haskey(pwf_data, "DCNV") && haskey(pwf_data, "DCCV") && haskey(pwf_data, "DELO"))
        @warn("DC line will not be parsed due to the absence of at least one those sections: DCBA, DCLI, DCNV, DCCV, DELO")
        return
    end
    @assert length(pwf_data["DCBA"]) == 4*length(pwf_data["DCLI"]) == 2*length(pwf_data["DCNV"]) == 2*length(pwf_data["DCCV"]) == 4*length(pwf_data["DELO"])

    for i1 in 1:length(pwf_data["DCLI"])
        i2 = 2*(i1 - 1) + 1, 2*i1
        i4 = 4*(i1 - 1) + 1, 4*(i1 - 1) + 2, 4*(i1 - 1) + 3, 4*i1 

        sub_data = Dict{String, Any}()

        @assert pwf_data["DCCV"][i2[1]]["CONVERTER CONTROL TYPE"] == pwf_data["DCCV"][i2[2]]["CONVERTER CONTROL TYPE"]
        mdc  = pwf_data["DCCV"][i2[1]]["CONVERTER CONTROL TYPE"]

        setvl = pwf_data["DCCV"][i2[1]]["SPECIFIED VALUE"]
        vschd = pwf_data["DCBA"][i4[1]]["VOLTAGE"]
        power_demand = mdc == 'P' ? abs(setvl) : mdc == 'C' ? abs(setvl / vschd / 1000) : 0

        sub_data["f_bus"] = pwf_data["DCNV"][i2[1]]["AC BUS"]
        sub_data["t_bus"] = pwf_data["DCNV"][i2[2]]["AC BUS"]

        # Assumption - bus status is defined on DELO section
        sub_data["br_status"] = pwf_data["DELO"][i1]["STATUS"] == 'L' ? 1 : 0

        sub_data["pf"] = power_demand
        sub_data["pt"] = power_demand
        sub_data["qf"] = 0.0
        sub_data["qt"] = 0.0

        # Assumption - vf & vt are directly the voltage for each bus, instead of what is indicated in DELO section
        sub_data["vf"] = filter(x -> x["NUMBER"] == sub_data["f_bus"], pwf_data["DBAR"])[1]["VOLTAGE"]/1000
        sub_data["vt"] = filter(x -> x["NUMBER"] == sub_data["t_bus"], pwf_data["DBAR"])[1]["VOLTAGE"]/1000

        # Assumption - the power demand sign is derived from the field looseness
        sub_data["pmaxf"] = pwf_data["DCCV"][i2[1]]["LOOSENESS"] == 'N' ? power_demand : -power_demand
        sub_data["pmint"] = pwf_data["DCCV"][i2[1]]["LOOSENESS"] == 'N' ? -power_demand : power_demand

        sub_data["pminf"] = 0.0
        sub_data["pmaxt"] = 0.0

        anmn = []
        for idx in i2
            angle = pwf_data["DCCV"][idx]["MINIMUM CONVERTER ANGLE"]
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

        sub_data["source_id"] = ["two-terminal dc", sub_data["f_bus"], sub_data["t_bus"], pwf_data["DCBA"][i4[1]]["NAME"]]
        sub_data["index"] = i1

        pm_data["dcline"]["$i1"] = sub_data
    end
end

function _handle_bs(shunt::Dict{String, Any})
    bs = 0
    for el in shunt["REACTANCE GROUPS"]
        if el["STATUS"] == 'L'
            bs += el["OPERATING UNITIES"]*el["REACTANCE"]
        end
    end
    return bs
end

# Assumption - if there are more than one shunt for the same bus we sum their values into one shunt (source: Organon)
# CAUTION: this might be an Organon error
function _pwf2pm_shunt!(pm_data::Dict, pwf_data::Dict)
    pm_data["shunt"] = Dict{String, Any}()

    fixed_shunt_bus = filter(x -> x["TOTAL REACTIVE POWER"] != 0.0, pwf_data["DBAR"])

    for bus in fixed_shunt_bus
        sub_data = Dict{String,Any}()

        sub_data["shunt_bus"] = bus["NUMBER"]
        sub_data["gs"] = 0.0        
        sub_data["bs"] =  bus["TOTAL REACTIVE POWER"] 

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

    # Assumption - the reactive generation is already considering the number of unities
    if haskey(pwf_data, "DCER")
        @warn("Switched shunt converted to fixed shunt, with default value gs=0.0")

        for shunt in pwf_data["DCER"]
            n = count(x -> x["shunt_bus"] == shunt["BUS"], values(pm_data["shunt"])) 

            sub_data = Dict{String,Any}()

            sub_data["shunt_bus"] = shunt["BUS"]
            sub_data["gs"] = 0.0
            sub_data["bs"] = shunt["REACTIVE GENERATION"]

            status = filter(x -> x["NUMBER"] == sub_data["shunt_bus"], pwf_data["DBAR"])[1]["STATUS"]
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

    if haskey(pwf_data, "DBSH")
        @warn("Switched shunt converted to fixed shunt, with default value gs=0.0")

        for shunt in pwf_data["DBSH"]
            # Assumption - shunt data should only consider devices without destination bus
            if shunt["TO BUS"] === nothing

                n = count(x -> x["shunt_bus"] == shunt["FROM BUS"], values(pm_data["shunt"])) 

                sub_data = Dict{String,Any}()

                sub_data["shunt_bus"] = shunt["FROM BUS"]
                sub_data["gs"] = 0.0
                
                sub_data["bs"] = _handle_bs(shunt)

                status = filter(x -> x["NUMBER"] == sub_data["shunt_bus"], pwf_data["DBAR"])[1]["STATUS"]
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

function organon_corrections!(pm_data::Dict, pwf_data::Dict)

    for (i, bus) in pm_data["bus"]
        pwf_bus = filter(x -> x["NUMBER"] == i, pwf_data["DBAR"])[1]
        if bus["bus_i"] == 2 && pwf_bus["MINIMUM REACTIVE GENERATION"] == pwf_bus["MAXIMUM REACTIVE GENERATION"] 
            @warn "Type 2 bus converted into type 1 because Qmin = Qmax"
            bus["bus_i"] = 1
        end
    end

end

function _parse_pwf_to_powermodels(pwf_data::Dict; validate::Bool, organon::Bool)
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

    if organon
        organon_corrections!(pm_data, pwf_data)
    end

    if validate
        PowerModels.correct_network_data!(pm_data)
    end
    
    return pm_data
end

"""
    parse_pwf_to_powermodels(filename::String, validate::Bool=false)::Dict

Parse .pwf file directly to PowerModels data structure
"""
function parse_pwf_to_powermodels(filename::String; validate::Bool=true, organon::Bool=false)::Dict
    pwf_data = open(filename) do f
        parse_pwf(f)
    end

    # Parse Dict to a Power Models format
    pm = _parse_pwf_to_powermodels(pwf_data, validate = validate, organon = organon)
    return pm
end

"""
    parse_pwf_to_powermodels(io::Io, validate::Bool=false)::Dict

"""
function parse_pwf_to_powermodels(io::IO; validate::Bool=true, organon::Bool=false)::Dict
    pwf_data = _parse_pwf_data(io)

    # Parse Dict to a Power Models format
    pm = _parse_pwf_to_powermodels(pwf_data, validate = validate, organon = organon)
    return pm
end
