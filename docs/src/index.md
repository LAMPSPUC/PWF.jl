# PWF.jl

```@meta
CurrentModule = PWF
```

---

PWF.jl is a Julia package for converting ANAREDE data format (".pwf") into a Julia dictionary.

Additionaly, PWF provides parsing .pwf file directly to [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) network data dictionary.

The implementations were made based on the ANAREDE user guide manual (v09).

**Quickguide**

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

The package parses all available sections into a julia dictionary. Every key represents a .pwf section as shown below:

**PWF Sections Available:**

- DBAR
- DLIN
- DGBT
- DGLT
- DGER
- DSHL
- DCBA
- DCLI
- DCNV
- DCCV
- DELO
- DCER
- DBSH (fban)
- DOPC
- DCTE

## PowerModels.jl converter

The package also allow converting .pwf file directly into PowerModels.jl network data structure:

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

## Contributing

- PRs such as adding new sections and fixing bugs are very welcome!
- For nontrivial changes, you'll probably want to first discuss the changes via issue.
