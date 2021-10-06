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