module ParserPWF

# using packages
using PowerModels

# including files
include("pwf.jl")
include("pwf_to_powermodels.jl")


export parse_pwf
export parse_pwf_to_powermodels

end # end module