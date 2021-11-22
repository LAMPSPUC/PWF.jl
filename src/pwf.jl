module PWF

# using packages
using PowerModels

# include PWF parser file
include("pwf.jl")

# include PowerModels converter files
include("pwf2pm/bus.jl")
include("pwf2pm/branch.jl")
include("pwf2pm/transformer.jl")
include("pwf2pm/load.jl")
include("pwf2pm/gen.jl")
include("pwf2pm/dcline.jl")
include("pwf2pm/shunt.jl")
include("pwf2pm/info.jl")

include("pwf2pm/correct/correct.jl")
include("pwf2pm/correct/organon.jl")
include("pwf2pm/correct/anarede.jl")

include("pwf2pm/pwf2pm.jl")

function parse_file(filename::String; validate::Bool=true, software = ANAREDE, pm::Bool = true, add_control_data::Bool=false)
    pm ? parse_pwf_to_powermodels(filename, validate = validate, software = software, add_control_data = add_control_data) : parse_pwf(filename)
end

function parse_file(io::IO; validate::Bool=true, software = ANAREDE, pm::Bool = true)
    pm ? parse_pwf_to_powermodels(io, validate = validate, software = software, add_control_data = add_control_data) : parse_pwf(filename)
end

export parse_file, ANAREDE, Organon

end # end module