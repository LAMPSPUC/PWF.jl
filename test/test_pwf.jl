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

        @test length(dict["DBAR"][1]) == 30
        @test length(dict["DLIN"][1]) == 30
    end

    @testset "DBAR" begin
        @test isa(dict["DBAR"][1]["ANGLE"], Float64)
        @test isa(dict["DBAR"][1]["MINIMUM REACTIVE GENERATION"], Float64)
        @test isa(dict["DBAR"][1]["MAXIMUM REACTIVE GENERATION"], Float64)
        @test isa(dict["DBAR"][1]["REACTIVE GENERATION"], Float64)
        @test isa(dict["DBAR"][1]["ACTIVE GENERATION"], Float64)
        @test isa(dict["DBAR"][1]["AREA"], Int)
        @test isa(dict["DBAR"][1]["NUMBER"], Int)
        @test isa(dict["DBAR"][1]["STATUS"], Char)
        @test isa(dict["DBAR"][1]["VOLTAGE"], Float64)
        @test isa(dict["DBAR"][1]["TYPE"], Int)
        @test isa(dict["DBAR"][1]["CHARGE DEFINITION VOLTAGE"], Float64)
    end

    @testset "DLIN" begin
        @test isa(dict["DLIN"][1]["EMERGENCY CAPACITY"], Float64)
        @test isa(dict["DLIN"][1]["EQUIPAMENT CAPACITY"], Float64)
        @test isa(dict["DLIN"][1]["NORMAL CAPACITY"], Float64)
        @test isa(dict["DLIN"][1]["CIRCUIT"], Int)
        @test isa(dict["DLIN"][1]["FROM BUS"], Int)
        @test isa(dict["DLIN"][1]["TO BUS"], Int)
        @test isa(dict["DLIN"][1]["REACTANCE"], Float64)
        @test isa(dict["DLIN"][1]["TAP"], Float64)
    end
end
