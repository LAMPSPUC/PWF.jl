module ParserPWF

# using packages
using PowerModels

# including files
include("pwf.jl")

function parse_pwf(filename::String)::Dict
    pwf_data = open(filename) do f
        parse_pwf(f)
    end

    return pwf_data
end

"""
    parse_pwf(io)

Reads PWF data in `io::IO`, returning a `Dict` of the data parsed into the
proper types.
"""
function parse_pwf(io::IO; validate = true)
    # Open file, read it and parse to a Dict 
    pwf_data = _parse_pwf_data(io)
    # Parse Dict to a Power Models format
    pm = _pwf_to_powermodels!(pwf_data, validate)
    return pm
end

end # end module