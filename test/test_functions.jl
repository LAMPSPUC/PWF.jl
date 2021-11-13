function check_same_dict(dict1::Dict, dict2::Dict, key; atol = 1e-3, ignore = ["source_version", "source_type", "name", "source_id"])
    if key in ignore
        return true
    end
    v1, v2 = dict1[key], dict2[key]
    if isa(v1, Dict)
        if isa(v2, Dict)
            return check_same_dict(v1,v2)
        else
            println("$v2 is not a dict")
            return false
        end
    elseif isa(v1, Real)
        if isa(v2, Real)
            if !isapprox(v1, v2, atol=atol)
                println("$v1 != $v2")
                return false
            end
        else
            println("$v2 is not a number")
            return false
        end
    else
        if v1 != v2
            println("$v1 != $v2")
            return false
        end
    end
    return true
end

function check_same_dict(dict1::Dict, dict2::Dict; atol = 1e-3, ignore = ["source_version", "source_type", "name", "source_id"])
    bools = Bool[]
    for (k,v1) in dict1
        if !(k in ignore)
            res = check_same_dict(dict1, dict2, k, ignore = ignore)
            push!(bools, res)
            if res
            else
            end
        end
    end
    return !(false in bools)
end
