# ParserPWF.jl

```@meta
CurrentModule = ParserPWF
```

---

ParserPWF.jl is a Julia package for converting ANAREDE data format (".pwf") into a Julia dictionary.

Additionaly, ParserPWF provides parsing .pwf file directly to [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) network data dictionary.

The implementations were made based on the ANAREDE user guide manual (v09).

**Quickguide**

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

**Incoming Sections:**

- DARE
- DCAI
- DCAR
- DCSC
- DGEI
- DGLT
- DINJ
- DMFL
- DMOT
- DMTE
- TITU

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
