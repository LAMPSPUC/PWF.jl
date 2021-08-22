module ParsePWF

include("pwf.jl")

"""
    parse_pwf(io)

Reads PWF data in `io::IO`, returning a `Dict` of the data parsed into the
proper types.
"""
function parse_pwf(io::IO)
    # Open file, read it and parse to a Dict 
    pwf_data = _parse_pwf_data(io)
    # Parse Dict to a Power Models format
    pm = _pwf_to_powermodels!(pwf_data)
    return pm
end

end # end module