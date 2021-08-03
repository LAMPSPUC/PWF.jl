using Test

path = pwd()

@testset "Intermediary functions"
    file = open(path*"/test/sistema_teste_radial.pwf")

    sections = _split_sections(file)
    @test isa(sections, Vector{Vector{String}})
    @test length(sections) == 5
    @test sections[1][1] == "TITU"

    data = Dict{String, Any}()
    _parse_section!(data, sections[1])
    @test haskey(data, "TITU")
    _parse_section!(data, sections[2])
    @test haskey(data, "DOPC")
    _parse_section!(data, sections[3])
    @test haskey(data, "DCTE")
    _parse_section!(data, sections[4])
    @test haskey(data, "DBAR")
    _parse_section!(data, sections[5])
    @test haskey(data, "DLIN")


@testset "Resulting Dict"
    file = open(path*"/test/sistema_teste_radial.pwf")
    dict = parse_pwf_data(file)

    @testset "Keys"
        @test haskey(dict, "TITU")
        @test haskey(dict, "DOPC")
        @test haskey(dict, "DCTE")
        @test haskey(dict, "DBAR")
        @test haskey(dict, "DLIN")

    @testset "Types"
        @test isa(dict["TITU"], String)
        @test isa(dict["DOPC"], Dict)
        @test isa(dict["DCTE"], Dict)
        @test isa(dict["DBAR"], Vector{Dict{String, Any}})
        @test isa(dict["DLIN"], Vector{Dict{String, Any}})

    @testset "Lengths"
        @test length(dict["DOPC"] == 13)
        @test length(dict["DCTE"] == 67)
        @test length(dict["DBAR"] == 9)
        @test length(dict["DLIN"] == 7)

        @test length(dict["DBAR"][1] == 30)
        @test length(dict["DLIN"][1] == 30)

    @testset "DBAR"
        @test isa(dict["DBAR"][1]["ANGLE"], Int)
        @test isa(dict["DBAR"][1]["MINIMUM REACTIVE GENERATION"], Int)
        @test isa(dict["DBAR"][1]["MAXIMUM REACTIVE GENERATION"], Int)
        @test isa(dict["DBAR"][1]["REACTIVE GENERATION"], Float64)
        @test isa(dict["DBAR"][1]["ACTIVE GENERATION"], Float64)
        @test isa(dict["DBAR"][1]["AREA"], Int)
        @test isa(dict["DBAR"][1]["NUMBER"], Int)
        @test isa(dict["DBAR"][1]["STATUS"], Char)
        @test isa(dict["DBAR"][1]["VOLTAGE"], Float64)
        @test isa(dict["DBAR"][1]["TYPE"], Int)
        @test isa(dict["DBAR"][1]["CHARGE DEFINITION VOLTAGE"], Float64)

    @testset "DLIN"
        @test isa(dict["DLIN"][1]["EMERGENCY CAPACITY"], Float64)
        @test isa(dict["DLIN"][1]["EQUIPAMENT CAPACITY"], Float64)
        @test isa(dict["DLIN"][1]["NORMAL CAPACITY"], Float64)
        @test isa(dict["DLIN"][1]["CIRCUIT"], Int)
        @test isa(dict["DLIN"][1]["FROM BUS"], Int)
        @test isa(dict["DLIN"][1]["TO BUS"], Int)
        @test isa(dict["DLIN"][1]["REACTANCE"], Float64)
        @test isa(dict["DLIN"][1]["TAP"], Float64)
