# Quick Start Guide

All functionalities of the PWF.jl package can be used by the following function

```julia
using PWF

file = "3bus.pwf"
pwf_dict = parse_file(file; pm = true, add_control_data = false)
```

The parameter `pm` indicates if the data should be converted to the PowerModels.jl format. `add_control_data` is used to inform if additional information regarding control actions should be included in the PowerModels.jl data. For more information about Control Actions visit the ControlPowerFlow.jl [documentation](https://github.com/LAMPSPUC/ControlPowerFlow.jl)

For more information about PowerModels.jl visit the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/)

## Parser

The package parses all available sections into a julia dictionary. Every key represents a .pwf section as shown below:

```julia
julia> PWF.parse_pwf(file)
Dict{String, Any} with 6 entries:
  "DLIN" => Dict{String, Any}[Dict("AGGREGATOR 10"=>nothing, "AGGREGATOR 5"=>nothing, "AGGR"…
  "name" => "3bus"
  "DBAR" => Dict{String, Any}[Dict("AGGREGATOR 10"=>nothing, "ANGLE"=>0.0, "MINIMUM REACTIV"…
  "TITU" => "Ande Case"…
  "DCTE" => Dict{String, Any}("TLVC"=>0.5, "APAS"=>90.0, "BASE"=>100.0, "STIR"=>1.0, "CPAR"…
  "DOPC" => Dict{String, Any}("CONT"=>'L', "CELO"=>'L' "MOST"=>'L', "MOSF"=>'L', "RCVG"=>'…
```

## PowerModels.jl converter

The package also allow converting .pwf file directly into PowerModels.jl network data structure:

```julia
julia> PWF.parse_pwf_to_powermodels(file)
Dict{String, Any} with 13 entries:
  "bus"            => Dict{String, Any}("1"=>Dict{String, Any}("zone"=>1, "bus_i"=>1, "bus_"…
  "source_type"    => "pwf"
  "name"           => "3bus"
  "dcline"         => Dict{String, Any}()
  "source_version" => "09"
  "branch"         => Dict{String, Any}("1"=>Dict{String, Any}("br_r"=>0.181, "shift"=>-0.0…
  "gen"            => Dict{String, Any}("1"=>Dict{String, Any}("pg"=>11.52, "model"=>2, "sh"…
  "storage"        => Dict{String, Any}()
  "switch"         => Dict{String, Any}()
  "baseMVA"        => 100.0
  "per_unit"       => false
  "shunt"          => Dict{String, Any}()
  "load"           => Dict{String, Any}("1"=>Dict{String, Any}("source_id"=>Any["load", 3, …
```
