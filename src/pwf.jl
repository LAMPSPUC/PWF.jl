#################################################################
#                                                               #
# This file provides functions for interfacing with .pwf files  #
#                                                               #
#################################################################

"""
A list of data file sections in the order that they appear in a PWF file
"""
const _dbar_dtypes = [("NUMBER", Int64, 1:5), ("OPERATION", Int64, 6), 
    ("STATUS", Char, 7), ("TYPE", Int64, 8), ("BASE VOLTAGE GROUP", Int64, 9:10),
    ("NAME", String, 11:22), ("VOLTAGE LIMIT GROUP", Int64, 23:24),
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


const _pwf_dtypes = Dict("DBAR" => _dbar_dtypes,
    "DLIN" => _dlin_dtypes
)

const _mnemonic_dopc = (filter(x -> x[1]%7 == 1, [i:i+3 for i in 1:66]),
                        filter(x -> x%7 == 6, 1:69), Char)

const _mnemonic_dcte = (filter(x -> x[1]%12 == 1, [i:i+3 for i in 1:68]),
                        filter(x -> x[1]%12 == 6, [i:i+5 for i in 1:66]), Float64)

const _mnemonic_pairs = Dict("DOPC" =>  _mnemonic_dopc,
    "DCTE" => _mnemonic_dcte
)

"""
    _split_sections(io)

Internal function. Parses a pwf file into an array where each
element corresponds to a section, divided by the delimiter 99999.
"""
function _split_sections(io::IO)
    lines = readlines(io)
    sections = Vector{String}[]

    titles = findall(x -> x == "TITU", lines)
    if length(titles) > 0
        last_title = titles[end]:titles[end] + 1
        push!(sections, lines[last_title])
    end
    idx_remove_titles = vcat(titles, titles .+ 1)
    lines = lines[setdiff(1:length(lines), idx_remove_titles)]

    section_delim = vcat(0, findall(x -> x == "99999", lines), findlast(x -> x == "FIM", lines))
    for i in 1:length(section_delim) - 1
        idx, next_idx = section_delim[i], section_delim[i + 1]
        push!(sections, lines[idx + 1:next_idx - 1])
    end
    return sections[1:end - 1]
end

"""
    _parse_line_element!(data, line, section)

Internal function. Parses a single line of data elements from a PWF file
and saves it into `data::Dict`.
"""
function _parse_line_element!(data::Dict, line::String, section::AbstractString)

    for (field, dtype, cols) in _pwf_dtypes[section]
        element = line[cols]

        try
            data[field] = parse(dtype, element)
        catch
            data[field] = element
        end
        
    end

end

function _parse_line_element!(data::Dict, lines::Vector{String}, section::AbstractString)

    mn_keys, mn_values, mn_type = _mnemonic_pairs[section]

    for line in lines
        for i in 1:length(mn_keys)
            k, v = mn_keys[i], mn_values[i]
            if v[end] <= length(line)
                try
                    data[line[k]] = parse(mn_type, line[v])
                catch
                    data[line[k]] = line[v]
                end    
            end
        end
    end
end

"""
    _parse_section(data, section_lines)

Internal function. Receives an array of lines corresponding to a PWF section,
transforms it into a Dict and saves it into `data::Dict`.
"""
function _parse_section!(data::Dict, section_lines::Vector{String})
    section = split(section_lines[1], " ")[1]

    if section == "TITU"
        section_data = section_lines[end]

    elseif section in keys(_mnemonic_pairs)
        section_data = Dict{String, Any}()
        _parse_line_element!(section_data, section_lines[3:end], section)

    elseif section in keys(_pwf_dtypes)
        section_data = Dict{String, Any}[]

        for line in section_lines[3:end]

            line_data = Dict{String, Any}()
            _parse_line_element!(line_data, line, section)

            push!(section_data, line_data)        
            
        end
    else
        @warn "Currently there is no support for $section parsing"
        section_data = nothing
    end

    data[section] = section_data
end

"""
    _parse_pwf_data(data_io)

Internal function. Receives a pwf file as an IOStream and parses into a Dict.
"""
function _parse_pwf_data(data_io::IO)

    sections = _split_sections(data_io)
    pwf_data = Dict{String, Any}()
    for section in sections
        _parse_section!(pwf_data, section)
    end
    
    return pwf_data
end