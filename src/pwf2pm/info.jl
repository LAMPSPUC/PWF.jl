function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict, option::String, status::Char)
    key = lowercase(option)
    value = status == 'L' ? true : status == 'D' ? false : error("Execution option $key status not defined")
    pm_data["info"][key] = value
end

function _pwf2pm_info!(pm_data::Dict, pwf_data::Dict)
    pm_data["info"] = Dict{String,Any}()
    if haskey(pwf_data, "DOPC")

        for (option,status) in pwf_data["DOPC"]
            _pwf2pm_info!(pm_data, pwf_data, option, status)
        end
    end

    if haskey(pwf_data, "DOPC IMPR")

        for (option,status) in pwf_data["DOPC IMPR"]
            _pwf2pm_info!(pm_data, pwf_data, option, status)
        end
    end
end
