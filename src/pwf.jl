#################################################################
#                                                               #
# This file provides functions for interfacing with .pwf files  #
#                                                               #
#################################################################

# This parser was develop using ANAREDE v09' user manual

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

const _dcba_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("TYPE", Int64, 8),
    ("POLARITY", String, 9), ("NAME", String, 10:21), ("VOLTAGE LIMIT GROUP", String, 22:23),
    ("VOLTAGE", Float64, 24:28), ("GROUND ELECTRODE", Float64, 67:71), ("DC LINK", Int64, 72:75)]

const _dcli_dtypes = [("FROM BUS", Int64, 1:4), ("OPERATION", Int64, 6), ("TO BUS", Int64, 9:12),
    ("CIRCUIT", Int64, 13:14), ("OWNER", Char, 16), ("RESISTANCE", Float64, 18:23),
    ("INDUCTANCE", Float64, 24:29), ("CAPACITY", Float64, 61:64)]

const _dcnv_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("AC BUS", Int64, 8:12),
    ("DC BUS", Int64, 14:17), ("NEUTRAL BUS", Int64, 19:22), ("OPERATION MODE", Char, 24),
    ("BRIDGES", Int64, 26), ("CURRENTS", Float64, 28:32), ("COMMUTATION REACTANCE", Float64, 24:38),
    ("SECONDARY VOLTAGE", Float64, 40:44), ("TRANSFORMER POWER", Float64, 46:50),
    ("REACTOR RESISTANCE", Float64, 52:56), ("REACTOR INDUCTANCE", Float64, 58:62),
    ("CAPACITANCE", Float64, 64:68), ("FREQUENCY", Float64, 70:71)]

const _dccv_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("LOOSENESS", Char, 8),
    ("INVERTER CONTROL MODE", Char, 9), ("CONVERTER CONTROL TYPE", Char, 10),
    ("SPECIFIED VALUE", Float64, 12:16), ("CURRENT MARGIN", Float64,18:22),
    ("MAXIMUM OVERCURRENT", Float64, 24:28), ("CONVERTER ANGLE", Float64, 30:34),
    ("MINIMUM CONVERTER ANGLE", Float64, 36:40), ("MAXIMUM CONVERTER ANGLE", Float64, 42:46),
    ("MINIMUM TRANSFORMER TAP", Float64, 48:52), ("MAXIMUM TRANSFORMER TAP", Float64, 54:58),
    ("TRANSFORMER TAP NUMBER OF STEPS", Int64, 60:61),
    ("MINIMUM DC VOLTAGE FOR POWER CONTROL", Float64, 63:66),
    ("TAP HI MVAR MODE", Float64, 68:72), ("TAP REDUCED VOLTAGE MODE", Float64, 74:78)]

const _delo_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("VOLTAGE", Float64, 8:12),
    ("BASE", Float64, 14:18), ("NAME", String, 20:39), ("HI MVAR MODE", Char, 41), ("STATUS", Char, 43)]

const _pwf_dtypes = Dict("DBAR" => _dbar_dtypes, "DLIN" => _dlin_dtypes,
    "DGBT" => _dgbt_dtypes, "DGLT" => _dglt_dtypes, "DGER" => _dger_dtypes,
    "DSHL" => _dshl_dtypes, "DCBA" => _dcba_dtypes, "DCLI" => _dcli_dtypes,
    "DCNV" => _dcnv_dtypes, "DCCV" => _dccv_dtypes, "DELO" => _delo_dtypes)

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

const _default_dcba = Dict("NUMBER" => nothing, "OPERATION" => 'A', "TYPE" => 0,
    "POLARITY" => nothing, "NAME" => nothing, "VOLTAGE LIMIT GROUP" => nothing,
    "VOLTAGE" => 0, "GROUND ELECTRODE" => 0.0, "DC LINK" => 1)

const _default_dcli = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => nothing, "OWNER" => nothing, "RESISTANCE" => nothing, "INDUCTANCE" => 0.0,
    "CAPACITY" => Inf)

const _default_dcnv = Dict("NUMBER" => nothing, "OPERATION" => 'A', "AC BUS" => nothing,
    "DC BUS" => nothing, "NEUTRAL BUS" => nothing, "OPERATION MODE" => nothing,
    "BRIDGES" => nothing, "CURRENTS" => nothing, "COMMUTATION REACTANCE" => nothing,
    "SECONDARY VOLTAGE" => nothing, "TRANSFORMER POWER" => nothing, "REACTOR RESISTANCE" => 0.0,
    "REACTOR INDUCTANCE" => 0.0, "CAPACITANCE" => Inf, "FREQUENCY" => 60.0)

const _default_dccv = Dict("NUMBER" => nothing, "OPERATION" => 'A', "LOOSENESS" => 'N',
    "INVERTER CONTROL MODE" => nothing, "CONVERTER CONTROL TYPE" => nothing,
    "SPECIFIED VALUE" => nothing, "CURRENT MARGIN" => 10.0, "MAXIMUM OVERCURRENT" => 9999,
    "CONVERTER ANGLE" => 0.0, "MINIMUM CONVERTER ANGLE" => 0.0,
    "MAXIMUM CONVERTER ANGLE" => 0.0, "MINIMUM TRANSFORMER TAP" => nothing,
    "MAXIMUM TRANSFORMER TAP" => nothing, "TRANSFORMER TAP NUMBER OF STEPS" => Inf,
    "MINIMUM DC VOLTAGE FOR POWER CONTROL" => 0.0, "TAP HI MVAR MODE" => nothing,
    "TAP REDUCED VOLTAGE MODE" => 1.0)

const _default_delo = Dict("NUMBER" => nothing, "OPERATION" => 'A', "VOLTAGE" => nothing,
    "BASE" => nothing, "NAME" => nothing, "HI MVAR MODE" => 'N', "STATUS" => 'L')

const _default_titu = ""

const _default_name = ""

const _pwf_defaults = Dict("DBAR" => _default_dbar, "DLIN" => _default_dlin, "DCTE" => _default_dcte,
    "DOPC" => _default_dopc, "TITU" => _default_titu, "name" => _default_name, "DGER" => _default_dger,
    "DGBT" => _default_dgbt, "DGLT" => _default_dglt, "DSHL" => _default_dshl, "DCBA" => _default_dcba,
    "DCLI" => _default_dcli, "DCNV" => _default_dcnv, "DCCV" => _default_dccv)


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

_needs_default(str::String) = unique(str) == [' ']
_needs_default(ch::Char) = ch == ' '

function _populate_defaults!(pwf_data::Dict{String, Any})

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


function parse_pwf(filename::String)::Dict
    pwf_data = open(filename) do f
        parse_pwf(f)
    end

    return pwf_data
end

"""
    parse_pwf(io)

Reads PWF data in `io::IO`, returning a `Dict` of the data parsed into the
proper types.
"""
function parse_pwf(io::IO)
    # Open file, read it and parse to a Dict 
    pwf_data = _parse_pwf_data(io)
    return pwf_data
end
