module PWF

# using packages
using PowerModels
using Memento

# setting up Memento
const _LOGGER = Memento.getlogger(@__MODULE__)

__init__() = Memento.register(_LOGGER)

function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.  Use the Memento package for more fine-grained control of logging.")
    Memento.setlevel!(Memento.getlogger(PWF), "error")
end

function logger_config!(level)
    Memento.config!(Memento.getlogger("PWF"), level)
end

# include PWF parser file
include("pwf2dict.jl")

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