#################################################################
#                                                               #
# This file provides functions for interfacing with .pwf files  #
#                                                               #
#################################################################

# This parser was develop using ANAREDE v09 user manual

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

const _dshl_dtypes = [("FROM BUS", Int64, 1:5), ("OPERATION", Int64, 7),
    ("TO BUS", Int64, 10:14), ("CIRCUIT", Int64, 15:16), ("SHUNT FROM", Float64, 18:23),
    ("SHUNT TO", Float64, 24:29), ("STATUS FROM", Char, 31:32, ("STATUS TO", Char, 34:35))]

const _dcer_dtypes = [("BUS", Int, 1:5), ("OPERATION", Char, 7), ("GROUP", Int64, 9:10),
    ("UNITIES", Int64, 12:13), ("CONTROLLED BUS", Int64, 15:19), ("INCLINATION", Float64, 21:26),
    ("REACTIVE GENERATION", Float64, 28:32), ("MINIMUM REACTIVE GENERATION", Float64, 33:37),
    ("MAXIMUM REACTIVE GENERATION", Float64, 38:42), ("CONTROL MODE", Char, 44), ("STATUS", Char, 46)]

const _fban_1_dtypes = [("FROM BUS", Int64, 1:5), ("OPERATION", Int64, 7),
    ("TO BUS", Int64, 10:14), ("CIRCUIT", Int64, 15:16), ("CONTROL MODE", Char, 18),
    ("MINIMUM VOLTAGE", Float64, 20:23), ("MAXIMUM VOLTAGE", Float64, 25:28),
    ("CONTROLLED BUS", Int64, 30:34), ("INITIAL REACTIVE INJECTION", Float64, 36:41),
    ("CONTROL TYPE", Char, 43), ("ERASE DBAR", Char, 45), ("EXTREMITY", Int64, 47:51)]

const _fban_2_dtypes = [("GROUP", Int64, 1:2), ("OPERATION", Char, 5), ("STATUS", Char, 7),
    ("UNITIES", Int64, 9:11), ("OPERATING UNITIES", Int64, 13:15),
    ("CAPACITOR REACTOR", Float64, 17:22)]

const _pwf_dtypes = Dict("DBAR" => _dbar_dtypes, "DLIN" => _dlin_dtypes, "DGBT" => _dgbt_dtypes,
    "DGLT" => _dglt_dtypes, "DGER" => _dger_dtypes, "DSHL" => _dshl_dtypes, "DCER" => _dcer_dtypes,
    "BUS AND VOLTAGE CONTROL" => _fban_1_dtypes, "REACTORS AND CAPACITORS BANKS" => _fban_2_dtypes,
    "DBSH" => [_fban_1_dtypes, _fban_2_dtypes])

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
    "TYPE" => 0, "BASE VOLTAGE GROUP" => " 0", "NAME" => nothing, "VOLTAGE LIMIT GROUP" => " 0",
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

const _default_dshl = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => nothing, "SHUNT FROM" => nothing, "SHUNT TO" => nothing,
    "STATUS FROM" => 'L', "STATUS TO" => 'L')

const _default_dcer = Dict("BUS" => nothing, "OPERATION" => 'A', "GROUP" => nothing,
    "UNITIES" => 1, "CONTROLLED BUS" => nothing, "INCLINATION" => nothing,
    "REACTIVE GENERATION" => nothing, "MINIMUM REACTIVE GENERATION" => nothing,
    "MAXIMUM REACTIVE GENERATION" => nothing, "CONTROL MODE" => 'I', "STATUS" => 'L')

const _default_fban_2 = Dict("GROUP" => nothing, "OPERATION" => 'A', "STATUS" => 'L',
    "UNITIES" => 1, "OPERATING UNITIES" => nothing, "CAPACITOR REACTOR" => nothing)

const _default_fban_1 = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => 1, "CONTROL MODE" => 'C', "MINIMUM VOLTAGE" => nothing,
    "MAXIMUM VOLTAGE" => nothing, "CONTROLLED BUS" => nothing,
    "INITIAL REACTIVE INJECTION" => 0.0, "CONTROL TYPE" => 'C', "ERASE DBAR" => 'N',
    "EXTREMITY" => nothing, "REACTOR CAPACITOR" => _default_fban_2)



const _default_titu = ""

const _default_name = ""

const _pwf_defaults = Dict("DBAR" => _default_dbar, "DLIN" => _default_dlin, "DCTE" => _default_dcte,
    "DOPC" => _default_dopc, "TITU" => _default_titu, "name" => _default_name, "DGER" => _default_dger,
    "DGBT" => _default_dgbt, "DGLT" => _default_dglt, "DSHL" => _default_dshl, "DCER" => _default_dcer,
    "DBSH" => _default_fban_1, "REACTOR CAPACITOR" => _default_fban_2)


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
            if !_needs_default(element)
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
                        if !_needs_default(line[v])
                            @warn "Could not parse $(line[v]) to $mn_type, setting it as a String"
                        end
                        !_needs_default(line[k]) ? data[line[k]] = line[v] : nothing
                    end
                else
                    !_needs_default(line[k]) ? data[line[k]] = line[v] : nothing
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
    _parse_section_element!(data, section_lines, section)
Internal function. Parses a section containing a system component.
Returns a Vector of Dict, where each entry corresponds to a single element.
"""
function _parse_section_element!(data::Vector{Dict{String, Any}}, section_lines::Vector{String}, section::AbstractString)

    if section == "DBSH"
        _parse_dbsh_section!(data, section_lines)
        return
    end

    first_line = _first_data_line(section_lines)
    for line in section_lines[first_line:end]

        line_data = Dict{String, Any}()
        _parse_line_element!(line_data, line, section)

        push!(data, line_data)        
        
    end

end

function _parse_dbsh_section!(data::Vector{Dict{String, Any}}, section_lines::Vector{String})

    sub_titles_idx = vcat(1, findall(x -> x == "FBAN", section_lines))
    for (i, idx) in enumerate(sub_titles_idx)

        if idx != sub_titles_idx[end]
            next_idx = sub_titles_idx[i + 1]
            _parse_section_element!(data, section_lines[idx:idx + 2], "BUS AND VOLTAGE CONTROL")

            rc = Dict{String, Any}[]
            _parse_section_element!(rc, section_lines[idx + 2:next_idx - 1], "REACTORS AND CAPACITORS BANKS")
            data[end]["REACTOR CAPACITOR"] = rc
        end

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
        _parse_section_element!(section_data, section_lines, section)

    else
        @warn "Currently there is no support for $section parsing"
        section_data = nothing
    end

    data[section] = section_data
end

_needs_default(str::String) = unique(str) == [' ']
_needs_default(ch::Char) = ch == ' '

function _populate_defaults!(pwf_data::Dict{String, Any})

    @warn "Populating defaults"

    for (section, section_data) in pwf_data
        if !haskey(_pwf_defaults, section)
            @warn "Parser doesn't have default values for section $(section)."
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
                    if _needs_default(component_value)
                        pwf_data[section][i][component] = default
                        _handle_special_defaults!(pwf_data, section, i, component)
                    end
                elseif isa(component_value, Dict) || isa(component_value, Vector{Dict{String,Any}})
                    sub_data = pwf_data[section][i]
                    _populate_section_defaults!(sub_data, component, component_value)
                    pwf_data[section][i] = sub_data
                end
            else
                pwf_data[section][i][component] = default
                _handle_special_defaults!(pwf_data, section, i, component)
            end
        end
        _handle_transformer_default!(pwf_data, section, i)
    end
end

function _populate_section_defaults!(pwf_data::Dict{String, Any}, section::String, section_data::Dict{String, Any})
    component_defaults = _pwf_defaults[section]

    for (component, default) in component_defaults
        if haskey(section_data, component)
            component_value = section_data[component]
            if isa(component_value, String) || isa(component_value, Char)
                if _needs_default(component_value)
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

function _handle_special_defaults!(pwf_data::Dict{String, Any}, section::String, i::Int, component::String)
    
    if section == "DBAR" && component == "MINIMUM REACTIVE GENERATION"
        bus_type = pwf_data[section][i]["TYPE"]
        if bus_type == 2
            pwf_data[section][i][component] = -9999.0
        else
            # If the reactive generation is different from zero, the limits will be the reactive generation itself
            if !isa(pwf_data[section][i]["REACTIVE GENERATION"], String)
                pwf_data[section][i][component] = pwf_data[section][i]["REACTIVE GENERATION"]
            end
        end
    end
    if section == "DBAR" && component == "MAXIMUM REACTIVE GENERATION"
        bus_type = pwf_data[section][i]["TYPE"]
        if bus_type == 2
            pwf_data[section][i][component] = 99999.0
        else
            # If the reactive generation is different from zero, the limits will be the reactive generation itself
            if !isa(pwf_data[section][i]["REACTIVE GENERATION"], String)
                pwf_data[section][i][component] = pwf_data[section][i]["REACTIVE GENERATION"]
            end
        end
    end

    if section == "DLIN" && component == "TAP"
        pwf_data[section][i]["TRANSFORMER"] = false
    end

end

_handle_transformer_default!(pwf_data::Dict{String, Any}, section::String, i::Int) =
    section == "DLIN" ? !haskey(pwf_data[section][i], "TRANSFORMER") ?
    pwf_data[section][i]["TRANSFORMER"] = true :
    @assert(!pwf_data[section][i]["TRANSFORMER"]) : nothing

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
            return pwf_data["DGBT"][1]["VOLTAGE"]
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
            return pwf_data["DGLT"][1]["LOWER BOUND"]
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
            return pwf_data["DGLT"][1]["UPPER BOUND"]
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
        for bus in pwf_data["DBAR"]
            sub_data = Dict{String,Any}()

            sub_data["bus_i"] = bus["NUMBER"]
            sub_data["bus_type"] = _handle_bus_type(bus)
            sub_data["area"] = pop!(bus, "AREA")
            sub_data["vm"] = pop!(bus, "VOLTAGE")/1000 # Implicit decimal point ignored
            sub_data["va"] = pop!(bus, "ANGLE")
            sub_data["zone"] = 1
            sub_data["name"] = pop!(bus, "NAME")

            sub_data["source_id"] = ["bus", "$(bus["NUMBER"])"]
            sub_data["index"] = bus["NUMBER"]

            sub_data["base_kv"] = _handle_base_kv(pwf_data, bus)
            sub_data["vmin"] = _handle_vmin(pwf_data, bus)
            sub_data["vmax"] = _handle_vmax(pwf_data, bus)

            idx = string(sub_data["index"])
            pm_data["bus"][idx] = sub_data
        end
    end

    
end

function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict)

    pm_data["branch"] = Dict{String, Any}()
    if haskey(pwf_data, "DLIN")
        for branch in pwf_data["DLIN"]
            if !branch["TRANSFORMER"]
                sub_data = Dict{String,Any}()

                sub_data["f_bus"] = pop!(branch, "FROM BUS")
                sub_data["t_bus"] = pop!(branch, "TO BUS")
                sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
                sub_data["br_x"] = pop!(branch, "REACTANCE") / 100
                sub_data["g_fr"] = 0.0
                sub_data["b_fr"] = _handle_b_fr(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])
                sub_data["g_to"] = 0.0
                sub_data["b_to"] = _handle_b_to(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])
                sub_data["tap"] = pop!(branch, "TAP")
                sub_data["shift"] = -pop!(branch, "LAG")
                sub_data["angmin"] = -360.0 # No limit
                sub_data["angmax"] = 360.0 # No limit
                sub_data["transformer"] = false

                if branch["STATUS"] == 'D'
                    sub_data["br_status"] = 0
                else
                    sub_data["br_status"] = 1
                end

                sub_data["source_id"] = ["branch", sub_data["f_bus"], sub_data["t_bus"], "01"]
                sub_data["index"] = length(pm_data["branch"]) + 1

                sub_data["rate_a"] = pop!(branch, "NORMAL CAPACITY")
                sub_data["rate_b"] = pop!(branch, "EMERGENCY CAPACITY")
                sub_data["rate_c"] = pop!(branch, "EQUIPAMENT CAPACITY")

                if sub_data["rate_a"] >= 9999
                    delete!(sub_data, "rate_a")
                end
                if sub_data["rate_b"] >= 9999
                    delete!(sub_data, "rate_b")
                end
                if sub_data["rate_c"] >= 9999
                    delete!(sub_data, "rate_c")
                end
    
                idx = string(sub_data["index"])
                pm_data["branch"][idx] = sub_data
            end
        end
    end
end

function _pwf2pm_load!(pm_data::Dict, pwf_data::Dict)

    pm_data["load"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            if bus["REACTIVE CHARGE"] != 0.0 || bus["ACTIVE CHARGE"] != 0.0
                sub_data = Dict{String,Any}()

                sub_data["load_bus"] = bus["NUMBER"]
                sub_data["pd"] = pop!(bus, "ACTIVE CHARGE")
                sub_data["qd"] = pop!(bus, "REACTIVE CHARGE")
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
    @warn("DGER not found, setting pmin as the bar active generation")
    bus = findfirst(x -> x["NUMBER"] == bus_i, pwf_data["DBAR"])
    return pwf_data["DBAR"][bus]["ACTIVE GENERATION"]
end

function _handle_pmax(pwf_data::Dict, bus_i::Int)
    if haskey(pwf_data, "DGER")
        bus = filter(x -> x["NUMBER"] == bus_i, pwf_data["DGER"])
        if length(bus) == 1
            return bus[1]["MAXIMUM ACTIVE GENERATION"]
        end
    end
    @warn("DGER not found, setting pmax as the bar active generation")
    bus = findfirst(x -> x["NUMBER"] == bus_i, pwf_data["DBAR"])
    return pwf_data["DBAR"][bus]["ACTIVE GENERATION"]
end

function _pwf2pm_generator!(pm_data::Dict, pwf_data::Dict)

    pm_data["gen"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            if bus["REACTIVE GENERATION"] != 0.0 || bus["ACTIVE GENERATION"] != 0.0
                sub_data = Dict{String,Any}()

                sub_data["gen_bus"] = bus["NUMBER"]
                sub_data["gen_status"] = 1
                sub_data["pg"] = bus["ACTIVE GENERATION"]
                sub_data["qg"] = bus["REACTIVE GENERATION"]
                sub_data["vg"] = pm_data["bus"]["$(bus["NUMBER"])"]["vm"]
                sub_data["mbase"] = _handle_base_mva(pwf_data)
                sub_data["pmin"] = _handle_pmin(pwf_data, bus["NUMBER"])
                sub_data["pmax"] = _handle_pmax(pwf_data, bus["NUMBER"])
                sub_data["qmin"] = haskey(bus, "MINIMUM REACTIVE GENERATION") ? bus["MINIMUM REACTIVE GENERATION"] : bus["REACTIVE GENERATION"]
                sub_data["qmax"] = haskey(bus, "MAXIMUM REACTIVE GENERATION") ? bus["MAXIMUM REACTIVE GENERATION"] : bus["REACTIVE GENERATION"]
    
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

function _pwf2pm_transformer!(pm_data::Dict, pwf_data::Dict) # Two-winding transformer
    if !haskey(pm_data, "branch")
        pm_data["branch"] = Dict{String, Any}()
        non_transformers = 0
    else
        non_transformers = length(pm_data["branch"])
    end

    if haskey(pwf_data, "DLIN")
        for branch in pwf_data["DLIN"]
            if branch["TRANSFORMER"]
                sub_data = Dict{String,Any}()

                sub_data["f_bus"] = pop!(branch, "FROM BUS")
                sub_data["t_bus"] = pop!(branch, "TO BUS")
                sub_data["br_r"] = pop!(branch, "RESISTANCE") / 100
                sub_data["br_x"] = pop!(branch, "REACTANCE") / 100
                sub_data["g_fr"] = 0.0
                sub_data["g_to"] = 0.0
                sub_data["tap"] = pop!(branch, "TAP")
                sub_data["shift"] = -pop!(branch, "LAG")
                sub_data["angmin"] = -360.0 # No limit
                sub_data["angmax"] = 360.0 # No limit
                sub_data["transformer"] = true

                if branch["STATUS"] == 'D'
                    sub_data["br_status"] = 0
                else
                    sub_data["br_status"] = 1
                end

                n = count(x -> x["f_bus"] == sub_data["f_bus"] && x["t_bus"] == sub_data["t_bus"], values(pm_data["branch"])) 
                sub_data["source_id"] = ["transformer", sub_data["f_bus"], sub_data["t_bus"], 0, "0$(n + 1)", 0]
                sub_data["index"] = length(pm_data["branch"]) + 1

                sub_data["b_fr"] = _handle_b_fr(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])
                sub_data["b_to"] = _handle_b_to(pm_data, pwf_data, sub_data["f_bus"], sub_data["t_bus"], branch["SHUNT SUSCEPTANCE"])

                sub_data["rate_a"] = pop!(branch, "NORMAL CAPACITY")
                sub_data["rate_b"] = pop!(branch, "EMERGENCY CAPACITY")
                sub_data["rate_c"] = pop!(branch, "EQUIPAMENT CAPACITY")

                if sub_data["rate_a"] >= 9999
                    delete!(sub_data, "rate_a")
                end
                if sub_data["rate_b"] >= 9999
                    delete!(sub_data, "rate_b")
                end
                if sub_data["rate_c"] >= 9999
                    delete!(sub_data, "rate_c")
                end
    
                idx = string(sub_data["index"])
                pm_data["branch"][idx] = sub_data
            end
        end
    end
end

# Analyzing PowerModels' raw parser, it was concluded that b_to & b_fr data was present in DSHL section
function _handle_b_fr(pm_data::Dict, pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64)
    i = count(x -> x["f_bus"] == f_bus && x["t_bus"] == t_bus, values(pm_data["branch"])) + 1
    b_fr = susceptance / 2.0
    if haskey(pwf_data, "DSHL")
        group = findall(x -> x["FROM BUS"] == f_bus && x["TO BUS"] == t_bus, pwf_data["DSHL"])
        if length(group) > 0 && length(group) >= i
            if pwf_data["DSHL"][group[i]]["SHUNT FROM"] !== nothing
                b_fr = pwf_data["DSHL"][group[i]]["SHUNT FROM"] / 100
            end
        end
    end
    return b_fr / 100
end

function _handle_b_to(pm_data, pwf_data::Dict, f_bus::Int, t_bus::Int, susceptance::Float64)
    i = count(x -> x["f_bus"] == f_bus && x["t_bus"] == t_bus, values(pm_data["branch"])) + 1
    b_to = susceptance / 2.0
    if haskey(pwf_data, "DSHL")
        group = findall(x -> x["FROM BUS"] == f_bus && x["TO BUS"] == t_bus, pwf_data["DSHL"])
        if length(group) > 0 && length(group) >= i
            if pwf_data["DSHL"][group[i]]["SHUNT TO"] !== nothing
                b_to = pwf_data["DSHL"][group[i]]["SHUNT TO"] / 100
            end
        end
    end
    return b_to / 100
end

# Assumption - if there are more than one shunt for the same bus we sum their values into one shunt (source: Organon)
# CAUTION: this might be an Organon error
function _pwf2pm_shunt!(pm_data::Dict, pwf_data::Dict)
    pm_data["shunt"] = Dict{String, Any}()

    fixed_shunt_bus = filter(x -> x["TOTAL REACTIVE POWER"] != 0.0, pwf_data["DBAR"])

    for bus in fixed_shunt_bus
        sub_data = Dict{String,Any}()

        sub_data["shunt_bus"] = bus["NUMBER"]
        sub_data["gs"] = 0.0        
        sub_data["bs"] =  bus["TOTAL REACTIVE POWER"] 

        if bus["STATUS"] == 'L'
            sub_data["status"] = 1
        elseif bus["STATUS"] == 'D'
            sub_data["status"] = 0
        end

        n = count(x -> x["shunt_bus"] == sub_data["shunt_bus"], values(pm_data["shunt"])) 
        sub_data["source_id"] = ["fixed shunt", sub_data["shunt_bus"], "0$(n+1)"]
        sub_data["index"] = length(pm_data["shunt"]) + 1

        idx = string(sub_data["index"])
        pm_data["shunt"][idx] = sub_data
    end

    # Assumption - the reactive generation is already considering the number of unities
    if haskey(pwf_data, "DCER")
        @warn("Switched shunt converted to fixed shunt, with default value gs=0.0")

        for shunt in pwf_data["DCER"]
            n = count(x -> x["shunt_bus"] == shunt["BUS"], values(pm_data["shunt"])) 

            sub_data = Dict{String,Any}()

            sub_data["shunt_bus"] = shunt["BUS"]
            sub_data["gs"] = 0.0
            sub_data["bs"] = shunt["REACTIVE GENERATION"]

            status = filter(x -> x["NUMBER"] == sub_data["shunt_bus"], pwf_data["DBAR"])[1]["STATUS"]
            if status == 'L'
                sub_data["status"] = 1
            elseif status == 'D'
                sub_data["status"] = 0
            end    

            sub_data["source_id"] = ["switched shunt", sub_data["shunt_bus"], "0$(n+1)"]
            sub_data["index"] = length(pm_data["shunt"]) + 1

            if _create_new_shunt(sub_data, pm_data)[1]
                idx = string(sub_data["index"])
                pm_data["shunt"][idx] = sub_data
            else
                idx = _create_new_shunt(sub_data, pm_data)[2]
                pm_data["shunt"][idx]["gs"] += sub_data["gs"]
                pm_data["shunt"][idx]["bs"] += sub_data["bs"]
            end
    end
    end

    if haskey(pwf_data, "DBSH")
        @warn("Switched shunt converted to fixed shunt, with default value gs=0.0")

        for shunt in pwf_data["DBSH"]
            # Assumption - shunt data should only consider devices without destination bus
            if shunt["TO BUS"] === nothing

                n = count(x -> x["shunt_bus"] == shunt["FROM BUS"], values(pm_data["shunt"])) 

                sub_data = Dict{String,Any}()

                sub_data["shunt_bus"] = shunt["FROM BUS"]
                sub_data["gs"] = 0.0
                sub_data["bs"] = shunt["INITIAL REACTIVE INJECTION"]

                status = filter(x -> x["NUMBER"] == sub_data["shunt_bus"], pwf_data["DBAR"])[1]["STATUS"]
                if status == 'L'
                    sub_data["status"] = 1
                elseif status == 'D'
                    sub_data["status"] = 0
                end    
    
                sub_data["source_id"] = ["switched shunt", sub_data["shunt_bus"], "0$(n+1)"]
                sub_data["index"] = length(pm_data["shunt"]) + 1

                if _create_new_shunt(sub_data, pm_data)[1]
                    idx = string(sub_data["index"])
                    pm_data["shunt"][idx] = sub_data
                else
                    idx = _create_new_shunt(sub_data, pm_data)[2]
                    pm_data["shunt"][idx]["gs"] += sub_data["gs"]
                    pm_data["shunt"][idx]["bs"] += sub_data["bs"]
                end
            end
        end
    end
end

function _create_new_shunt(sub_data::Dict, pm_data::Dict)
    for (idx, value) in pm_data["shunt"]
        if value["shunt_bus"] == sub_data["shunt_bus"] && value["source_id"][1] == sub_data["source_id"][1]
            return false, idx
        end
    end
    return true    
end


function _pwf_to_powermodels!(pwf_data::Dict, validate::Bool)
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
    _pwf2pm_transformer!(pm_data, pwf_data)
    _pwf2pm_shunt!(pm_data, pwf_data)

    # ToDo: fields not yet contemplated by the parser

    pm_data["dcline"] = Dict{String,Any}()
    pm_data["storage"] = Dict{String,Any}()
    pm_data["switch"] = Dict{String,Any}()

    if validate
        PowerModels.correct_network_data!(pm_data)
    end
    
    return pm_data
end