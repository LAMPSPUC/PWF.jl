function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict, option::String, status::Char, section::String)
    key = lowercase(option)
    value = status == 'L' ? true : status == 'D' ? false : error("Execution option $key status not defined")
    pm_data["info"][section][key] = value
end

function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict, option::String, value::Real, section::String)
    key = lowercase(option)
    pm_data["info"][section][key] = value
end

function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict)
    pm_data["info"] = Dict{String,Dict{String,Any}}()
    info_sections = ["DOPC", "DOPC IMPR", "DCTE"]

    for section in info_sections
        if haskey(pwf_data, section)

            pm_data["info"][section] = Dict{String,Any}()
            for (option,value) in pwf_data[section]
                _pwf2pm_info!(pm_data, pwf_data, option, value, section)
            end
        end
    end
end
