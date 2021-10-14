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
    sub_data["vf"] = bus_f["VOLTAGE"]
    sub_data["vt"] = bus_t["VOLTAGE"]

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