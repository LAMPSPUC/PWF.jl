module ParsePWF

include("pwf.jl")

function parse_pwf(io::IO)
    pwf_data = parse_pwf(io) # Open file, read it and parse to a Dict 
    pm = pwf_to_powermodels!(pwf_data) # Parse Dict to a Power Models format
    return pm
end

end # end module