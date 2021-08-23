#################################################################
#                                                               #
# This file provides functions for interfacing with .pwf files  #
#                                                               #
#################################################################

"""
A list of data file sections in the order that they appear in a PWF file
"""
const _dbar_dtypes = [("NUMBER", Int64, 1:5), ("OPERATION", Int64, 6), 
    ("STATUS", Char, 7), ("TYPE", Int64, 8), ("BASE VOLTAGE GROUP", String, 9:10),
    ("NAME", String, 11:22), ("VOLTAGE LIMIT GROUP", String, 23:24),
    ("VOLTAGE", Float64, 25:28), ("ANGLE", Float64, 29:32),
    ("ACTIVE GENERATION", Float64, 33:37), ("REACTIVE GENERATION", Float64, 38:42),
    ("MINIMUM REACTIVE GENERATION", Float64, 43:47),
    ("MAXIMUM REACTIVE GENERATION",Float64, 48:52), ("CONTROLLED BUS", Int64, 53:58),
    ("ACTIVE CHARGE", Float64, 59:63), ("REACTIVE CHARGE", Float64, 64:68),
    ("TOTAL REACTIVE POWER", Float64, 69:73), ("AREA", Int64, 74:76),
    ("CHARGE DEFINITION VOLTAGE", Float64, 77:80), ("VISUALIZATION", Int64, 81),
    ("AGGREGATOR 1", Int64, 82:84), ("AGGREGATOR 2", Int64, 85:87),
    ("AGGREGATOR 3", Int64, 88:90), ("AGGREGATOR 4", Int64, 91:93),
    ("AGGREGATOR 5", Int64, 94:96), ("AGGREGATOR 6", Int64, 97:99),
    ("AGGREGATOR 7", Int64, 100:102), ("AGGREGATOR 8", Int64, 103:105),
    ("AGGREGATOR 9", Int64, 106:108), ("AGGREGATOR 10", Int64, 109:111)]

const _dlin_dtypes = [("FROM BUS", Int64, 1:5), ("OPENING FROM BUS", Char, 6),
    ("OPERATION", Int64, 8), ("OPENING TO BUS", Char, 10), ("TO BUS", Int64, 11:15),
    ("CIRCUIT", Int64, 16:17), ("STATUS", Char, 18), ("OWNER", Char, 19),
    ("RESISTANCE", Float64, 21:26), ("REACTANCE", Float64, 27:32),
    ("SHUNT SUSCEPTANCE", Float64, 33:38), ("TAP", Float64, 39:43),
    ("MINIMUM TAP", Float64, 44:48), ("MAXIMUM TAP", Float64, 49:53),
    ("LAG", Float64, 54:58), ("CONTROLLED BUS", Int64, 59:64),
    ("NORMAL CAPACITY", Float64, 65:68), ("EMERGENCY CAPACITY", Float64, 69:72),
    ("NUMBER OF TAPS", Int64, 73:74), ("EQUIPAMENT CAPACITY", Float64, 75:78),
    ("AGGREGATOR 1", Int64, 79:81), ("AGGREGATOR 2", Int64, 82:84),
    ("AGGREGATOR 3", Int64, 85:87), ("AGGREGATOR 4", Int64, 88:90),
    ("AGGREGATOR 5", Int64, 91:93), ("AGGREGATOR 6", Int64, 94:96),
    ("AGGREGATOR 7", Int64, 97:99), ("AGGREGATOR 8", Int64, 100:102),
    ("AGGREGATOR 9", Int64, 103:105), ("AGGREGATOR 10", Int64, 106:108)]

const _dgbt_dtypes = [("GROUP", String, 1:2), ("VOLTAGE", Float64, 4:8)]

const _dglt_dtypes = [("GROUP", String, 1:2), ("LOWER BOUND", Float64, 4:8),
    ("UPPER BOUND", Float64, 10:14), ("LOWER EMERGENCY BOUND", Float64, 16:20),
    ("UPPER EMERGENCY BOUND", Float64, 22:26)]

const _dger_dtypes = [("NUMBER", Int, 1:5), ("OPERATION", Char, 7),
    ("MINIMUM ACTIVE GENERATION", Float64, 9:14),
    ("MAXIMUM ACTIVE GENERATION", Float64, 16:21),
    ("PARTICIPATION FACTOR", Float64, 23:27),
    ("REMOTE CONTROL PARTICIPATION FACTOR", Float64, 29:33),
    ("NOMINAL POWER FACTOR", Float64, 35:39), ("ARMATURE SERVICE FACTOR", Float64, 41:44),
    ("ROTOR SERVICE FACTOR", Float64, 46:49), ("CHARGE ANGLE", Float64, 51:54),
    ("MACHINE REACTANCE", Float64, 56:60), ("NOMINAL APPARENT POWER", Float64, 62:66)]

const _pwf_dtypes = Dict("DBAR" => _dbar_dtypes, "DLIN" => _dlin_dtypes,
    "DGBT" => _dgbt_dtypes, "DGLT" => _dglt_dtypes,
    "DGER" => _dger_dtypes)

const _mnemonic_dopc = (filter(x -> x[1]%7 == 1, [i:i+3 for i in 1:66]),
                        filter(x -> x%7 == 6, 1:69), Char)

const _mnemonic_dcte = (filter(x -> x[1]%12 == 1, [i:i+3 for i in 1:68]),
                        filter(x -> x[1]%12 == 6, [i:i+5 for i in 1:66]), Float64)

"""
Sections which contains pairs that set values to some contants (DCTE)
and specify some execution control options (DOPC). 
"""
const _mnemonic_pairs = Dict("DOPC" =>  _mnemonic_dopc,
    "DCTE" => _mnemonic_dcte
)

const _default_dbar = Dict("NUMBER" => nothing, "OPERATION" => 'A', "STATUS" => 'L',
    "TYPE" => 0, "BASE VOLTAGE GROUP" => 0, "NAME" => nothing, "VOLTAGE LIMIT GROUP" => 0,
    "VOLTAGE" => 1.0, "ANGLE" => 0.0, "ACTIVE GENERATION" => 0.0,
    "REACTIVE GENERATION" => 0.0, "MINIMUM REACTIVE GENERATION" => 0.0,
    "MAXIMUM REACTIVE GENERATION" => 0.0, "CONTROLLED BUS" => nothing,
    "ACTIVE CHARGE" => 0.0, "REACTIVE CHARGE" => 0.0, "TOTAL REACTIVE POWER" => 0.0,
    "AREA" => 1, "CHARGE DEFINITION VOLTAGE" => 1.0, "VISUALIZATION" => 0,
    "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, 
    "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, 
    "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, 
    "AGGREGATOR 10" => nothing)

const _default_dlin = Dict("FROM BUS" => nothing, "OPENING FROM BUS" => 'L',
    "OPERATION" => 'A', "OPENING TO BUS" => 'L', "TO BUS" => nothing, "CIRCUIT" => nothing,
    "STATUS" => 'L', "OWNER" => 'F', "RESISTANCE" => 0.0, "REACTANCE" => nothing,
    "SHUNT SUSCEPTANCE" => 0.0, "TAP" => 1.0, "MINIMUM TAP" => nothing,
    "MAXIMUM TAP" => nothing, "LAG" => 0.0, "CONTROLLED BUS" => nothing,
    "NORMAL CAPACITY" => Inf, "EMERGENCY CAPACITY" => Inf, "NUMBER OF TAPS" => 33,
    "EQUIPAMENT CAPACITY" => Inf, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing,
    "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing,
    "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing,
    "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing)

const _default_dopc = Dict()

const _default_dcte = Dict("TEPA" => 0.1, "TEPR" => 0.1, "TLPR" => 0.1, "TLVC" => .5,
    "TLTC" => 0.01, "TETP" => 5.0, "TBPA" => 5.0, "TSFR" => 0.01, "TUDC" => 0.001,
    "TADC" => 0.01, "BASE" => 100.0, "DASE" => 100.0, "ZMAX" => 500.0, "ACIT" => 30,
    "LPIT" => 50, "LFLP" => 10, "LFIT" => 10, "DCIT" => 10, "VSIT" => 10, "LCRT" => 23,
    "LPRT" => 60, "LFCV" => 1, "TPST" => 0.2, "QLST" => 0.2, "EXST" => 0.4, "TLPP" => 1.0,
    "TSBZ" => 0.01, "TSBA" => 5.0, "PGER" => 30.0, "VDVN" => 40.0, "VDVM" => 200.0,
    "ASTP" => 0.05, "VSTP" => 5.0, "CSTP" => 5.0, "VFLD" => 70, "HIST" => 0, "ZMIN" => 0.001,
    "PDIT" => 10, "ICIT" => 50, "FDIV" => 2.0, "DMAX" => 5, "ICMN" => 0.05, "VART" => 5.0,
    "TSTP" => 33, "TSDC" => 0.02, "ASDC" => 1, "ICMV" => 0.5, "APAS" => 90, "CPAR" => 70,
    "VAVT" => 2.0, "VAVF" => 5.0, "VMVF" => 15.0, "VPVT" => 2.0, "VPVF" => 5.0,
    "VPMF" => 10.0, "VSVF" => 20.0, "VINF" => 1.0, "VSUP" => 1.0, "TLSI" => 0.0)

const _default_dger = Dict("NUMBER" => nothing, "OPERATION" => 'A',
    "MINIMUM ACTIVE GENERATION" => 0.0, "MAXIMUM ACTIVE GENERATION" => 99999.0,
    "PARTICIPATION FACTOR" => 0.0, "REMOTE CONTROL PARTICIPATION FACTOR" => 100.0,
    "NOMINAL POWER FACTOR" => nothing, "ARMATURE SERVICE FACTOR" => nothing,
    "ROTOR SERVICE FACTOR" => nothing, "CHARGE ANGLE" => nothing,
    "MACHINE REACTANCE" => nothing, "NOMINAL APPARENT POWER" => nothing)

const _default_dgbt = Dict("GROUP" => 0, "VOLTAGE" => 1.0)

const _default_dglt = Dict("GROUP" => nothing,  "LOWER BOUND" => 0.8, "UPPER BOUND" => 1.2,
    "LOWER EMERGENCY BOUND" => 0.8, "UPPER EMERGENCY BOUND" => 1.2)

const _default_titu = ""

const _default_name = ""

const _pwf_defaults = Dict("DBAR" => _default_dbar, "DLIN" => _default_dlin, "DCTE" => _default_dcte,
    "DOPC" => _default_dopc, "TITU" => _default_titu, "name" => _default_name, "DGER" => _default_dger,
    "DGBT" => _default_dgbt, "DGLT" => _default_dglt)


const title_identifier = "TITU"
const end_section_identifier = "99999"

function _remove_titles_from_file_lines(file_lines::Vector{String}, section_titles_idx::Vector{Int64})
    remove_titles_idx = vcat(section_titles_idx, section_titles_idx .+ 1)
    file_lines_without_titles_idx = setdiff(1:length(file_lines), remove_titles_idx)
    file_lines = file_lines[file_lines_without_titles_idx]
    return file_lines
end

"""
    _split_sections(io)

Internal function. Parses a pwf file into an array where each
element corresponds to a section, divided by the delimiter 99999.
"""
function _split_sections(io::IO)
    file_lines = readlines(io)
    sections = Vector{String}[]

    section_titles_idx = findall(line -> line == title_identifier, file_lines)
    if !isempty(section_titles_idx)
        last_section_title_idx = section_titles_idx[end]:section_titles_idx[end] + 1
        push!(sections, file_lines[last_section_title_idx])
    end

    file_lines = _remove_titles_from_file_lines(
        file_lines, section_titles_idx
    )

    section_delim = vcat(
        0, 
        findall(x -> x == end_section_identifier, file_lines)
    )

    num_sections = length(section_delim) - 1

    for i in 1:num_sections
        section_begin_idx = section_delim[i] + 1
        section_end_idx   = section_delim[i + 1] - 1
        push!(sections, file_lines[section_begin_idx:section_end_idx])
    end

    return sections
end

"""
    _parse_line_element!(data, line, section)

Internal function. Parses a single line of data elements from a PWF file
and saves it into `data::Dict`.
"""
function _parse_line_element!(data::Dict{String, Any}, line::String, section::AbstractString)

    line_length = _pwf_dtypes[section][end][3][end]
    if length(line) < line_length
        extra_characters_needed = line_length - length(line)
        line = line * repeat(" ", extra_characters_needed)
    end

    for (field, dtype, cols) in _pwf_dtypes[section]
        element = line[cols]

        try
            if dtype != String && dtype != Char
                data[field] = parse(dtype, element)
            else
                data[field] = element
            end
        catch
            if !needs_default(element)
                @warn "Could not parse $element to $dtype, setting it as a String"
            end
            data[field] = element
        end
        
    end

end

function _parse_line_element!(data::Dict{String, Any}, lines::Vector{String}, section::AbstractString)

    mn_keys, mn_values, mn_type = _mnemonic_pairs[section]

    for line in lines
        for i in 1:length(mn_keys)
            k, v = mn_keys[i], mn_values[i]
            if v[end] <= length(line)

            if mn_type != String && mn_type != Char
                try
                     data[line[k]] = parse(mn_type, line[v])
                catch
                    if !needs_default(line[v])
                        @warn "Could not parse $(line[v]) to $mn_type, setting it as a String"
                    end
                    data[line[k]] = line[v]
                end
            else
                data[line[k]] = line[v]
            end
                    
            end
        end
    end
end

function _first_data_line(section_lines::Vector{String})
    section_name = section_lines[1]
    if section_name == "DGER" # Sections which don't have a column index
        return 2
    else
        return 3
    end
end

"""
    _parse_section_element(data, section_lines, section)
Internal function. Parses a section containing a system component.
Returns a Vector of Dict, where each entry corresponds to a single element.
"""
function _parse_section_element(data::Vector{Dict{String, Any}}, section_lines::Vector{String}, section::AbstractString)

    first_line = _first_data_line(section_lines)
    for line in section_lines[first_line:end]

        line_data = Dict{String, Any}()
        _parse_line_element!(line_data, line, section)

        push!(data, line_data)        
        
    end

end
"""
    _parse_section(data, section_lines)

Internal function. Receives an array of lines corresponding to a PWF section,
transforms it into a Dict and saves it into `data::Dict`.
"""
function _parse_section!(data::Dict{String, Any}, section_lines::Vector{String})
    section = split(section_lines[1], " ")[1]

    if section == title_identifier
        section_data = section_lines[end]

    elseif section in keys(_mnemonic_pairs)
        section_data = Dict{String, Any}()
        _parse_line_element!(section_data, section_lines[3:end], section)

    elseif section in keys(_pwf_dtypes)
        section_data = Dict{String, Any}[]
        _parse_section_element(section_data, section_lines, section)

    else
        @warn "Currently there is no support for $section parsing"
        section_data = nothing
    end

    data[section] = section_data
end

needs_default(str::String) = unique(str) == [' ']
needs_default(ch::Char) = ch == ' '

function _populate_defaults!(pwf_data::Dict{String, Any})

    for (section, section_data) in pwf_data
        if !haskey(_pwf_defaults, section)
            @warn "Parser don't have default values for section $(section)."
        else
            _populate_section_defaults!(pwf_data, section, section_data)
        end
    end

end

function _populate_section_defaults!(pwf_data::Dict{String, Any}, section::String, section_data::Vector{Dict{String, Any}})
    component_defaults = _pwf_defaults[section]

    for (i, element) in enumerate(section_data)
        for (component, default) in component_defaults
            if haskey(element, component)
                component_value = element[component]
                if isa(component_value, String) || isa(component_value, Char)
                    if needs_default(component_value)
                        pwf_data[section][i][component] = default
                    end
                end
            else
                pwf_data[section][i][component] = default
            end
        end
    end
end

function _populate_section_defaults!(pwf_data::Dict{String, Any}, section::String, section_data::Dict{String, Any})
    component_defaults = _pwf_defaults[section]

    for (component, default) in component_defaults
        if haskey(section_data, component)
            component_value = section_data[component]
            if isa(component_value, String) || isa(component_value, Char)
                if needs_default(component_value)
                    pwf_data[section][component] = default
                end
            end
        else
            pwf_data[section][component] = default
        end
    end
end

function _populate_section_defaults!(pwf_data::Dict{String, Any}, section::String, section_data::AbstractString)
    # Filename indicator, does not need a default
end
"""
    _parse_pwf_data(data_io)

Internal function. Receives a pwf file as an IOStream and parses into a Dict.
"""
function _parse_pwf_data(data_io::IO)

    sections = _split_sections(data_io)
    pwf_data = Dict{String, Any}()
    pwf_data["name"] = match(r"^\<file\s[\/\\]*(?:.*[\/\\])*(.*)\.pwf\>$", lowercase(data_io.name)).captures[1]
    for section in sections
        _parse_section!(pwf_data, section)
    end

    _populate_defaults!(pwf_data)
    
    return pwf_data
end

function _handle_base_kv(pwf_data::Dict, bus::Dict)
    group_identifier = bus["BASE VOLTAGE GROUP"]
    if haskey(pwf_data, "DGBT")
        if length(pwf_data["DGBT"]) == 1 && pwf_data["DGBT"][1]["GROUP"] != group_identifier
            @warn "Only one base voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGBT"][1]["GROUP"])"
        else
            group = filter(x -> x["GROUP"] == group_identifier, pwf_data["DGBT"])
            @assert length(group) == 1
            return group[1]["VOLTAGE"]
        end
    else
        return 1.0 # Default value for this field in .pwf
    end
end

function _handle_vmin(pwf_data::Dict, bus::Dict)
    group_identifier = bus["VOLTAGE LIMIT GROUP"]
    if haskey(pwf_data, "DGLT")
        if length(pwf_data["DGLT"]) == 1 && pwf_data["DGLT"][1]["GROUP"] != group_identifier
            @warn "Only one limit voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGLT"][1]["GROUP"])"
        else
            group = filter(x -> x["GROUP"] == group_identifier, pwf_data["DGLT"])
            @assert length(group) == 1
            return group[1]["LOWER BOUND"]
        end
    else
        return 0.9 # Default value given in the PSS(R)E specification
    end    
end

function _handle_vmax(pwf_data::Dict, bus::Dict)
    group_identifier = bus["VOLTAGE LIMIT GROUP"]
    if haskey(pwf_data, "DGLT")
        if length(pwf_data["DGLT"]) == 1 && pwf_data["DGLT"][1]["GROUP"] != group_identifier
            @warn "Only one limit voltage group defined, setting bus $(bus["NUMBER"]) as group $(pwf_data["DGLT"][1]["GROUP"])"
        else
            group = filter(x -> x["GROUP"] == group_identifier, pwf_data["DGLT"])
            @assert length(group) == 1
            return group[1]["UPPER BOUND"]
        end
    else
        return 1.1 # Default value given in the PSS(R)E specification
    end    
end

function _handle_bus_type(bus::Dict)
    bus_type = pop!(bus, "TYPE")
    dict_bus_type = Dict(0 => 1, 3 => 1, # PQ
    1 => 2, # PV
    2 => 3 # Referência
    )
    return dict_bus_type[bus_type]
end

function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict)

    pm_data["bus"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for (i,bus) in enumerate(pwf_data["DBAR"])
            sub_data = Dict{String,Any}()

            sub_data["bus_i"] = bus["NUMBER"]
            sub_data["bus_type"] = _handle_bus_type(bus)
            sub_data["area"] = pop!(bus, "AREA")
            sub_data["vm"] = pop!(bus, "VOLTAGE")/1000 # Implicit decimal point ignored
            sub_data["va"] = pop!(bus, "ANGLE")*pi/180 # Degrees to radians
            sub_data["zone"] = 1
            sub_data["name"] = pop!(bus, "NAME")

            sub_data["source_id"] = ["bus", "$(bus["NUMBER"])"]
            sub_data["index"] = i

            sub_data["base_kv"] = _handle_base_kv(pwf_data, bus)
            sub_data["vmin"] = _handle_vmin(pwf_data, bus)
            sub_data["vmax"] = _handle_vmax(pwf_data, bus)

            idx = string(sub_data["index"])
            pm_data["bus"][idx] = sub_data
        end
    end

    
end

#ToDo
#_handle_rates(pwf_data) = 10000, 10000, 10000

function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict)

    pm_data["branch"] = Dict{String, Any}()
    if haskey(pwf_data, "DLIN")
        for (i, branch) in enumerate(pwf_data["DLIN"])
            sub_data = Dict{String,Any}()

            sub_data["f_bus"] = pop!(branch, "FROM BUS")
            sub_data["t_bus"] = pop!(branch, "TO BUS")
            sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
            sub_data["br_x"] = pop!(branch, "REACTANCE") / 100
            sub_data["g_fr"] = 0.0
            sub_data["b_fr"] = branch["SHUNT SUSCEPTANCE"] / 2.0
            sub_data["g_to"] = 0.0
            sub_data["b_to"] = branch["SHUNT SUSCEPTANCE"] / 2.0
            sub_data["tap"] = pop!(branch, "TAP")
            sub_data["shift"] = pop!(branch, "LAG")
            sub_data["br_status"] = 1
            sub_data["angmin"] = -360.0 # No limit
            sub_data["angmax"] = 360.0 # No limit
            sub_data["transformer"] = false

            sub_data["source_id"] = ["branch", sub_data["f_bus"], sub_data["t_bus"], "01"]
            sub_data["index"] = i

            #ToDo
            #sub_data["rate_a"] = _handle_rates(pwf_data)[1]
            #sub_data["rate_b"] = _handle_rates(pwf_data)[2]
            #sub_data["rate_c"] = _handle_rates(pwf_data)[3]

            idx = string(sub_data["index"])
            pm_data["branch"][idx] = sub_data
        end
    end
end

function _pwf2pm_load!(pm_data::Dict, pwf_data::Dict)

    pm_data["load"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            if bus["REACTIVE CHARGE"] > 0.0 || bus["ACTIVE CHARGE"] > 0.0
                sub_data = Dict{String,Any}()

                sub_data["load_bus"] = bus["NUMBER"]
                sub_data["pd"] = pop!(bus, "ACTIVE CHARGE") / 100
                sub_data["qd"] = pop!(bus, "REACTIVE CHARGE") / 100
                sub_data["status"] = 1

                sub_data["source_id"] = ["load", sub_data["load_bus"], "1 "]
                sub_data["index"] = length(pm_data["load"]) + 1
            
                idx = string(sub_data["index"])
                pm_data["load"][idx] = sub_data
            end
        end
    end
end

function _handle_pmin(pwf_data::Dict, bus_i::Int)
    if haskey(pwf_data, "DGER")
        bus = filter(x -> x["NUMBER"] == bus_i, pwf_data["DGER"])
        if length(bus) == 1
            return bus[1]["MINIMUM ACTIVE GENERATION"]
        end
    end    
    return 0.0 # Default value for this field in pwf
end

function _handle_pmax(pwf_data::Dict, bus_i::Int)
    if haskey(pwf_data, "DGER")
        bus = filter(x -> x["NUMBER"] == bus_i, pwf_data["DGER"])
        if length(bus) == 1
            return bus[1]["MAXIMUM ACTIVE GENERATION"]
        end
    end
    return 99999.0 # Default value for this field in pwf
end

function _pwf2pm_generator!(pm_data::Dict, pwf_data::Dict)

    pm_data["gen"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            if bus["REACTIVE GENERATION"] > 0.0 || bus["ACTIVE GENERATION"] > 0.0
                sub_data = Dict{String,Any}()

                sub_data["gen_bus"] = bus["NUMBER"]
                sub_data["gen_status"] = 1
                sub_data["pg"] = pop!(bus, "ACTIVE GENERATION")
                sub_data["qg"] = pop!(bus, "REACTIVE GENERATION")
                sub_data["vg"] = pm_data["bus"]["$(bus["NUMBER"])"]["vm"]
                sub_data["mbase"] = _handle_base_mva(pwf_data)
                sub_data["pmin"] = _handle_pmin(pwf_data, bus["NUMBER"])
                sub_data["pmax"] = _handle_pmax(pwf_data, bus["NUMBER"])
                sub_data["qmin"] = pop!(bus, "MINIMUM REACTIVE GENERATION") / 100
                sub_data["qmax"] = pop!(bus, "MAXIMUM REACTIVE GENERATION") / 100
    
                # Default Cost functions
                sub_data["model"] = 2
                sub_data["startup"] = 0.0
                sub_data["shutdown"] = 0.0
                sub_data["ncost"] = 2
                sub_data["cost"] = [1.0, 0.0]
    
                sub_data["source_id"] = ["generator", sub_data["gen_bus"], "1 "]
                sub_data["index"] = length(pm_data["gen"]) + 1
                
                idx = string(sub_data["index"])
                pm_data["gen"][idx] = sub_data
            end
        end
    end
end

function _handle_base_mva(pwf_data::Dict)
    baseMVA = 100.0 # Default value for this field in .pwf
    if haskey(pwf_data, "DCTE")
        if haskey(pwf_data["DCTE"], "BASE")
            baseMVA = pwf_data["DCTE"]["BASE"]
        end
    end
    return baseMVA
end

function _pwf_to_powermodels!(pwf_data::Dict)
    pm_data = Dict{String,Any}()

    pm_data["per_unit"] = false
    pm_data["source_type"] = "pwf"
    pm_data["source_version"] = "09"
    pm_data["name"] = pwf_data["name"]

    pm_data["baseMVA"] = _handle_base_mva(pwf_data)

    _pwf2pm_bus!(pm_data, pwf_data)
    _pwf2pm_branch!(pm_data, pwf_data)
    _pwf2pm_load!(pm_data, pwf_data)
    _pwf2pm_generator!(pm_data, pwf_data)

    
    return pm_data
end