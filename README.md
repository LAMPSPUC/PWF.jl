<img src="docs/src/assets/lampspucpptreduced.png" align="right" width=300>
<h1>PWF.jl</h1>

<br>
<br>

---

PWF.jl is a Julia package for converting ANAREDE data format (".pwf") into a Julia dictionary.

Additionaly, PWF provides parsing .pwf file directly to [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) network data dictionary.

The implementations were made based on the ANAREDE user guide manual (v09).

**Quickstart**

Until the creating of PWF.jl, '.pwf' files could only be parsed through Brazilian commercial softwares, such as ANAREDE and Organon. Therefore, the Brazilian Power System community was compelled to use one of the two solutions to run Power Flow analysis.

PWF.jl unlocks the power of open-source to the Power System community. Therefore, now, anyone can read the standard Brazilian file ('.pwf') and run steady-state electrical analysis with state-of-the-art methodologies. For the Power Flow algorithm, we encourage the usage of the package PowerModels.jl, which already have integration with the PWF.jl package.

To perform Power Flow analysis using PWF.jl in Julia, follow the steps bellow:

1. First of all, make sure you have [Visual Studio Code](https://code.visualstudio.com/) and [Julia Language](https://julialang.org/downloads/) Long-term support (LTS) 1.6.6 configured correctly;

2. Then, add PWF.jl and PowerModels.jl to known packages;

```julia
using Pkg

Pkg.add("PWF")
Pkg.add("PowerModels")
```

3. Finally, you are ready to perform power flow analysis

```julia
using PWF, PowerModels

network_path = "network.pwf"

network = PWF.parse_file(network_path)

results = PowerModels.run_ac_pf(network)

results["solution"]["bus"]["1"]["vm"] # folution for voltage magniture of bus 1
results["solution"]["bus"]["1"]["va"] # solution for voltage angle     of bus 1
```

For more information about PowerModels.jl visit the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/)

## Parser

The package parses all available sections into a julia dictionary. Each key represents a .pwf section as shown below:

```julia
julia> parse_file(file)
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
- DBSH
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
- DARE
- DCAI
- DCAR
- DGEI
- DINJ
- DMFL
- DMOT
- DMTE
- DAGR
- DCMT
- DTPF

## PowerModels.jl converter

The package also allow converting .pwf file directly into PowerModels.jl network data structure:

```julia
julia> parse_file(file; pm = true)
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

julia> data = parse_file(file; pm = true, software = ANAREDE)

julia> data = parse_file(file; pm = true, software = Organon)
```

**Additional data inside PWF files**

If parse_file' argument add_control_data is set to true (default = false), additional information present on the PWF file that is not used by PowerModels will be stored inside each element in the field "control_data", such as the example below:

```julia
julia> data = parse_file(file, pm = true, add_control_data = true);

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
