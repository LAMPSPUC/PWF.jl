<img src="docs/lampspucpptreduced.png" alt="MarineGEO circle logo" align="right" width=300>
<h1>ParserPWF.jl</h1>

<br>

---

ParserPWF.jl is a Julia package for converting ANAREDE data format (".pwf") into [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) network data dictionary. The implementations were made based on the ANAREDE user guide manual (v09).

**Quickstart**

Parsing a .pwf file is as simple as:

```julia
using ParserPWF

file = "3bus.pwf"
network_data = parse_pwf(file)
```

Then you are ready to use PowerModels.jl

```julia
using PowerModels

run_ac_pf(network_data)
```

For more information about PowerModels.jl visit the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/)

**PWF Sections Available:**

- DBAR
- DLIN
- DGBT
- DGLT
- DGER
- DSHL
- DOPC
- DCTE

**Incoming Sections:**

- DARE
- DBSH
- DCAI
- DCAR
- DCBA
- DCCV
- DCER
- DCLI
- DCNV
- DCSC
- DELO
- DGEI
- DGLT
- DINJ
- DMFL
- DMOT
- DMTE
- TITU

**Contributing**

- PRs such as adding new sections and fixing bugs are very welcome!
- For nontrivial changes, you'll probably want to first discuss the changes via issue.
