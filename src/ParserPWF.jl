module ParsePWF

# using packages
using PowerModels
# including files
include("pwf.jl")
# -----------------------------------------------------------------------------------------

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