"Needed due to Dict{String, Any} error in instantiate_model when parsing a JSON with info section"
function _handle_info_dict_type!(data::Dict)
    if haskey(data, "info")
        info = Dict{Any, Any}(
            "parameters" => data["info"]["parameters"],
            "actions"    => data["info"]["actions"]
        )
        data["info"] = info
    end
    return 
end

function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict, option::String, status::Char, section::String)
    key = lowercase(option)
    value = status == 'L' ? true : status == 'D' ? false : error("Execution option $key status not defined")
    pm_data["info"]["actions"][key] = value
end

function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict, option::String, value::Real, section::String)
    key = lowercase(option)
    pm_data["info"]["parameters"][key] = value
end

function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict)
    pm_data["info"] = Dict("actions" => Dict{String,Any}(), "parameters" => Dict{String,Any}())
    info_sections = ["DOPC", "DOPC IMPR", "DCTE"]

    for section in info_sections
        if haskey(pwf_data, section)

            for (option,value) in pwf_data[section]
                _pwf2pm_info!(pm_data, pwf_data, option, value, section)
            end
        end
    end
end
