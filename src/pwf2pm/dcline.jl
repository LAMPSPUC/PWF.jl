function _pwf2pm_dcline!(pm_data::Dict, pwf_data::Dict, link::Dict)

    sub_data = Dict{String, Any}()

    # Assumption - bus status is defined on DELO section
    sub_data["br_status"] = link["STATUS"] == 'L' ? 1 : 0

    dcba_keys = findall(x -> x["DC LINK"] == link["NUMBER"], pwf_data["DCBA"])
    @assert length(dcba_keys) == 4
    dict_dcba = Dict{Int,Dict}()
    for key in dcba_keys
        dc_bus = pwf_data["DCBA"][key]
        dict_dcba[dc_bus["NUMBER"]] = dc_bus
    end

    dcnv_keys = findall(x -> x["DC BUS"] in keys(dict_dcba), pwf_data["DCNV"])
    @assert length(dcnv_keys) == 2
    dict_dcnv = Dict{Int,Dict}()
    for key in dcnv_keys
        converter = pwf_data["DCNV"][key]
        dict_dcnv[converter["NUMBER"]] = converter
    end

    dccv_keys = findall(x -> x["NUMBER"] in keys(dict_dcnv), pwf_data["DCCV"])
    @assert length(dccv_keys) == 2
    dict_dccv = Dict{Char,Dict}()
    for key in dccv_keys
        converter_control = pwf_data["DCCV"][key]
        number = pwf_data["DCCV"][key]["NUMBER"]
        dict_dccv[dict_dcnv[number]["OPERATION MODE"]] = converter_control
    end

    dcli_keys = findall(x -> x["FROM BUS"] in keys(dict_dcba) && x["TO BUS"] in keys(dict_dcba), pwf_data["DCLI"])
    @assert length(dcli_keys) == 1
    dict_dcli = Dict{String,Dict}()
    dict_dcli["1"] = pwf_data["DCLI"][dcli_keys[1]]

    @assert dict_dccv['R']["CONVERTER CONTROL TYPE"] == dict_dccv['I']["CONVERTER CONTROL TYPE"]
    mdc  = dict_dccv['R']["CONVERTER CONTROL TYPE"]

    setvl = dict_dccv['R']["SPECIFIED VALUE"]

    rect, inv = dict_dccv['R']["NUMBER"], dict_dccv['I']["NUMBER"]
    rect_bus, inv_bus = dict_dcnv[rect]["DC BUS"], dict_dcnv[inv]["DC BUS"]
    vschd = dict_dcba[rect_bus]["VOLTAGE"]
    rdc = dict_dcli["1"]["RESISTANCE"]
    current = setvl / vschd
    loss = current^2 * rdc

    # Assumption - rectifier power has negative value, inverter has a positive one
    # Our formulation is only prepared for power, not current control
    # pf = mdc == 'P' ? abs(setvl[1]) : mdc == 'C' ? - abs(setvl[1] / vschd[1] / 1000) : 0
    # pt = mdc == 'P' ? - abs(setvl[2]) : mdc == 'C' ? abs(setvl[2] / vschd[2] / 1000) : 0

    pf = mdc == 'P' ? abs(setvl) : Memento.error(_LOGGER, "The formulation is prepared only for power control")
    pt = mdc == 'P' ? - abs(setvl) + loss : Memento.error(_LOGGER, "The formulation is prepared only for power control")

    sub_data["f_bus"] = dict_dcnv[rect]["AC BUS"]
    sub_data["t_bus"] = dict_dcnv[inv]["AC BUS"]

    sub_data["pf"] = pf
    sub_data["pt"] = pt
    sub_data["qf"] = 0.0
    sub_data["qt"] = 0.0

    # Assumption - vf & vt are directly the voltage for each bus, instead of what is indicated in DELO section
    bus_f = pwf_data["DBAR"]["$(sub_data["f_bus"])"]
    bus_t = pwf_data["DBAR"]["$(sub_data["t_bus"])"]
    sub_data["vf"] = bus_f["VOLTAGE"]
    sub_data["vt"] = bus_t["VOLTAGE"]

    # Assumption - the power demand sign is derived from the field looseness
    sub_data["pmaxf"] = dict_dccv['R']["LOOSENESS"] == 'N' ? pf : -pf
    sub_data["pmint"] = dict_dccv['I']["LOOSENESS"] == 'N' ? -pt : pt

    sub_data["pminf"] = 0.0
    sub_data["pmaxt"] = 0.0

    anmn = []
    for idx in ['R', 'I']
        angle = dict_dccv[idx]["MINIMUM CONVERTER ANGLE"]
        if abs(angle) <= 90.0
            push!(anmn, angle)
        else
            push!(anmn, 0)
            Memento.warn(_LOGGER, "$key outside reasonable limits, setting to 0 degress")
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

    sub_data["source_id"] = ["two-terminal dc", sub_data["f_bus"], sub_data["t_bus"], link["NAME"]]
    sub_data["index"] = link["NUMBER"]

    pm_data["dcline"]["$(link["NUMBER"])"] = sub_data
end

function _pwf2pm_dcline!(pm_data::Dict, pwf_data::Dict)

    pm_data["dcline"] = Dict{String, Any}()

    if !(haskey(pwf_data, "DCBA") && haskey(pwf_data, "DCLI") && haskey(pwf_data, "DCNV") && haskey(pwf_data, "DCCV") && haskey(pwf_data, "DELO"))
        Memento.warn(_LOGGER, "DC line will not be parsed due to the absence of at least one those sections: DCBA, DCLI, DCNV, DCCV, DELO")
        return
    end
    @assert length(pwf_data["DCBA"]) == 4*length(pwf_data["DCLI"]) == 2*length(pwf_data["DCNV"]) == 2*length(pwf_data["DCCV"]) == 4*length(pwf_data["DELO"])

    for (i,link) in pwf_data["DELO"]
        _pwf2pm_dcline!(pm_data, pwf_data, link)
    end
end