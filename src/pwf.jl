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

"""
Sections which contains pairs that set values to some contants (DCTE)
and specify some execution control options (DOPC). 
"""
const _mnemonic_pairs = Dict("DOPC" =>  _mnemonic_dopc,
    "DCTE" => _mnemonic_dcte
)


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

    for (field, dtype, cols) in _pwf_dtypes[section]
        element = line[cols]

        try
            if dtype != String && dtype != Char
                data[field] = parse(dtype, element)
            else
                data[field] = element
            end
        catch
            @warn "Could not parse $element to $dtype, setting it as a String"
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
                    @warn "Could not parse $(line[v]) to $mn_type, setting it as a String"
                    data[line[k]] = line[v]
                end
            else
                data[line[k]] = line[v]
            end
                    
            end
        end
    end
end

"""
    _parse_section_element(data, section_lines, section)
Internal function. Parses a section containing a system component.
Returns a Vector of Dict, where each entry corresponds to a single element.
"""
function _parse_section_element(data::Vector{Dict{String, Any}}, section_lines::Vector{String}, section::AbstractString)

    for line in section_lines[3:end]

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
        _parse_section_element(section_data, section_lines[3:end], section)

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


function _pwf2pm_bus!(pm_data::Dict, pwf_data::Dict) #, import_all::Bool)

    pm_data["bus"] = Dict{String, Any}()
    if haskey(pwf_data, "DBAR")
        for bus in pwf_data["DBAR"]
            sub_data = Dict{String,Any}()

            sub_data["bus_i"] = bus["NUMBER"]
            sub_data["bus_type"] = pop!(bus, "TYPE")
            sub_data["area"] = pop!(bus, "AREA")
            sub_data["vm"] = pop!(bus, "VOLTAGE")
            sub_data["va"] = pop!(bus, "ANGLE")
            sub_data["zone"] = 1
            sub_data["name"] = pop!(bus, "NAME")

            sub_data["source_id"] = ["bus", "$(bus["NUMBER"])"]
            sub_data["index"] = pop!(bus, "NUMBER")

            sub_data["base_kv"] = 1.0
            if haskey(pwf_data, "DGBT")
                sub_data["base_kv"] = pwf_data["DGBT"][4:8]
            end

            sub_data["vmin"] = 0.8
            sub_data["vmax"] = 1.2
            if haskey(pwf_data, "DGLT")
                sub_data["vmin"] = pwf_data["DGLT"][4:8]
                sub_data["vmax"] = pwf_data["DGLT"][10:14]
            end

            # if import_all
            #     _import_remaining_keys!(sub_data, bus)
            # end

            idx = string(sub_data["index"])
            pm_data["bus"][idx] = sub_data
        end
    end

    
end

function _pwf2pm_branch!(pm_data::Dict, pwf_data::Dict) #, import_all::Bool)

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
            # sub_data["rate_a"] = 10000
            # sub_data["rate_b"] = 10000
            # sub_data["rate_c"] = 10000
            sub_data["tap"] = pop!(branch, "TAP")
            sub_data["shift"] = pop!(branch, "LAG")
            sub_data["br_status"] = 1
            sub_data["angmin"] = 0.0
            sub_data["angmax"] = 0.0
            sub_data["transformer"] = false

            sub_data["source_id"] = ["branch", sub_data["f_bus"], sub_data["t_bus"], "1 "]
            sub_data["index"] = i

            # if import_all
            #     _import_remaining_keys!(sub_data, branch; exclude=["B", "BI", "BJ"])
            # end

            # if sub_data["rate_a"] == 0.0
            #     delete!(sub_data, "rate_a")
            # end
            # if sub_data["rate_b"] == 0.0
            #     delete!(sub_data, "rate_b")
            # end
            # if sub_data["rate_c"] == 0.0
            #     delete!(sub_data, "rate_c")
            # end

            idx = string(sub_data["index"])
            pm_data["branch"][idx] = sub_data
        end
    end
end
