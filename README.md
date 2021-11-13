<img src="docs/src/assets/lampspucpptreduced.png" align="right" width=300>
<h1>ParserPWF.jl</h1>

<br>
<br>

---

ParserPWF.jl is a Julia package for converting ANAREDE data format (".pwf") into a Julia dictionary.

Additionaly, ParserPWF provides parsing .pwf file directly to [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) network data dictionary.

The implementations were made based on the ANAREDE user guide manual (v09).

**Quickstart**

Parsing a .pwf file to Julia dictionary is as simple as:

```julia
using ParserPWF

file = "3bus.pwf"
pwf_dict = parse_pwf(file)
```

Converting the .pwf file into PowerModels.jl network data dictionary:

```julia
network_data = parse_pwf_to_powermodels(file)
```

Then you are ready to use PowerModels!

```julia
using PowerModels, Ipopt

run_ac_pf(network_data, Ipopt.Optimizer)
```

For more information about PowerModels.jl visit the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/)

## Parser

The package parses all available sections into a julia dictionary. Every key represents a .pwf section as shown below:

```julia
julia> ParserPWF.parse_pwf(file)
Dict{String, Any} with 6 entries:
  "DLIN" => Dict{String, Any}[Dict("AGGREGATOR 10"=>nothing, "AGGREGATOR 5"=>nothing, "AGGR"…
  "name" => "3bus"
  "DBAR" => Dict{String, Any}[Dict("AGGREGATOR 10"=>nothing, "ANGLE"=>0.0, "MINIMUM REACTIV"…
  "TITU" => "Ande Case"…
  "DCTE" => Dict{String, Any}("TLVC"=>0.5, "APAS"=>90.0, "BASE"=>100.0, "STIR"=>1.0, "CPAR"…
  "DOPC" => Dict{String, Any}("CONT"=>'L', "CELO"=>'L' "MOST"=>'L', "MOSF"=>'L', "RCVG"=>'…
```

**PWF Sections Available:**

- DBAR
- DBSH (fban)
- DCBA
- DCCV
- DCER
- DCLI
- DCNV
- DCSC
- DCTE
- DELO
- DGBT
- DGER
- DGLT
- DLIN
- DOPC
- DSHL

  **Incoming Sections:**

- DARE
- DCAI
- DCAR
- DGEI
- DINJ
- DMFL
- DMOT
- DMTE

## PowerModels.jl converter

The package also allow converting .pwf file directly into PowerModels.jl network data structure:

```julia
julia> ParserPWF.parse_pwf_to_powermodels(file)
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

**Network Data Sections Available:**

- bus
- gen
- load
- branch
- dcline
- shunt

**Incoming Network Data Sections:**

- switch
- storage

**Two parsing modes comprehended**

There are two main softwares used for parsing PWF files and each one does slightly different assumptions to the data parsed. For more information, visit the documentation.

```julia

julia> data = parse_file(file; software = ANAREDE)

julia> data = parse_file(file; software = Organon)
```

**Additional data inside PWF files**

Additional information existing in a PWF file that is not used by PowerModels is stored inside each element in the field "control_data", such as the example below:

```julia
julia> data["shunt"]["1"]["control_data"]
Dict{String, Any} with 9 entries:
  "vmmax"              => 1.029
  "section"            => "DBAR"
  "shunt_control_type" => 3
  "bsmin"              => 0.0
  "shunt_type"         => 2
  "bsmax"              => 0.0
  "inclination"        => nothing
  "vmmin"              => 1.029
  "controlled_bus"     => 1
```

## Contributing

- PRs such as adding new sections and fixing bugs are very welcome!
- For nontrivial changes, you'll probably want to first discuss the changes via issue. Suggestions are super welcome!
