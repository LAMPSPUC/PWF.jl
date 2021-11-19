abstract type PFSoftware end

"Organon software corrections"
mutable struct Organon <: PFSoftware end

"Anarede software corrections"
mutable struct ANAREDE <: PFSoftware end

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

function _fix_shunt_voltage_bounds(shunt::Dict, pm_data::Dict)
    shunt["control_data"]["vmmin"] = pm_data["bus"]["$(shunt["shunt_bus"])"]["vm"]
    shunt["control_data"]["vmmax"] = pm_data["bus"]["$(shunt["shunt_bus"])"]["vm"]
end

function _pwf2pm_corrections!(pm_data::Dict, pwf_data::Dict, software::PFSoftware)
    _pwf2pm_corrections_shunt!(pm_data, software)
    _pwf2pm_corrections_gen!(pm_data, pwf_data, software)
    _pwf2pm_corrections_PV!(pm_data, pwf_data, software)
    _pwf2pm_corrections_PQ!(pm_data, software)
   
    return 
end

function _set_controlled_bus_voltage_bounds!(pm_data::Dict, shunt_control_data::Dict)
    ctrl_bus = shunt_control_data["controlled_bus"]
    pm_data["bus"]["$ctrl_bus"]["control_data"]["vmmin"] = pop!(shunt_control_data, "vmmin")
    pm_data["bus"]["$ctrl_bus"]["control_data"]["vmmax"] = pop!(shunt_control_data, "vmmax")
end

function _correct_pwf_network_data(pm_data::Dict)
    mva_base = pm_data["baseMVA"]

    rescale        = x -> x/mva_base

    if haskey(pm_data, "shunt")
        for (i, shunt) in pm_data["shunt"]
            if haskey(shunt, "control_data")
                PowerModels._apply_func!(shunt["control_data"], "bsmin", rescale)
                PowerModels._apply_func!(shunt["control_data"], "bsmax", rescale)

                _set_controlled_bus_voltage_bounds!(pm_data, shunt["control_data"])
            end
        end
    end

end


