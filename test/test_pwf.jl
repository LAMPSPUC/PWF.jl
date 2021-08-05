@testset "Intermediary functions" begin
    file = open(joinpath(@__DIR__,"data/sistema_teste_radial.pwf"))

    sections = ParsePWF._split_sections(file)
    @test isa(sections, Vector{Vector{String}})
    @test length(sections) == 5
    @test sections[1][1] == "TITU"

    data = Dict{String, Any}()
    ParsePWF._parse_section!(data, sections[1])
    @test haskey(data, "TITU")
    ParsePWF._parse_section!(data, sections[2])
    @test haskey(data, "DOPC")
    ParsePWF._parse_section!(data, sections[3])
    @test haskey(data, "DCTE")
    ParsePWF._parse_section!(data, sections[4])
    @test haskey(data, "DBAR")
    ParsePWF._parse_section!(data, sections[5])
    @test haskey(data, "DLIN")
end


@testset "Resulting Dict" begin
    file = open(joinpath(@__DIR__,"data/sistema_teste_radial.pwf"))
    dict = ParsePWF._parse_pwf_data(file)

    @testset "Keys" begin
        @test haskey(dict, "TITU")
        @test haskey(dict, "DOPC")
        @test haskey(dict, "DCTE")
        @test haskey(dict, "DBAR")
        @test haskey(dict, "DLIN")
    end

    @testset "Types" begin
        @test isa(dict, Dict)
        @test isa(dict["TITU"], String)
        @test isa(dict["DOPC"], Dict)
        @test isa(dict["DCTE"], Dict)
        @test isa(dict["DBAR"], Vector{Dict{String, Any}})
        @test isa(dict["DLIN"], Vector{Dict{String, Any}})
    end

    @testset "Lengths" begin
        @test length(dict["DOPC"]) == 13
        @test length(dict["DCTE"]) == 67
        @test length(dict["DBAR"]) == 9
        @test length(dict["DLIN"]) == 7

        for item in dict["DBAR"]
            @test length(item) == 30
        end
        for item in dict["DLIN"]
            @test length(item) == 30
        end
    end

    @testset "DBAR" begin
        for item in dict["DBAR"]
            @test isa(item["ANGLE"], Float64)
            @test isa(item["MINIMUM REACTIVE GENERATION"], Float64)
            @test isa(item["MAXIMUM REACTIVE GENERATION"], Float64)
            @test isa(item["REACTIVE GENERATION"], Float64)
            @test isa(item["ACTIVE GENERATION"], Float64)
            @test isa(item["AREA"], Int)
            @test isa(item["NUMBER"], Int)
            @test isa(item["STATUS"], Char)
            @test isa(item["VOLTAGE"], Float64)
            @test isa(item["TYPE"], Int)
            @test isa(item["CHARGE DEFINITION VOLTAGE"], Float64)
        end
    end

    @testset "DLIN" begin
        for item in dict["DLIN"]
            @test isa(item["EMERGENCY CAPACITY"], Float64)
            @test isa(item["EQUIPAMENT CAPACITY"], Float64)
            @test isa(item["NORMAL CAPACITY"], Float64)
            @test isa(item["CIRCUIT"], Int)
            @test isa(item["FROM BUS"], Int)
            @test isa(item["TO BUS"], Int)
            @test isa(item["REACTANCE"], Float64)
            @test isa(item["TAP"], Float64)
        end
    end
end
