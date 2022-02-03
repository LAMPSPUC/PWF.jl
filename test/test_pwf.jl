@testset "PWF to Dict" begin
    @testset "Intermediary functions" begin
        file = open(joinpath(@__DIR__,"data/pwf/test_system.pwf"))

        file_lines, sections = PWF._split_sections(file)
        @test isa(file_lines, Vector{String})
        @test isa(sections, Dict{String, Vector{Int64}})
        @test length(sections) == 5

        data = Dict{String, Any}()
        PWF._parse_section!(data, "TITU", sections["TITU"], file_lines)
        @test haskey(data, "TITU")
        PWF._parse_section!(data, "DOPC IMPR", sections["DOPC IMPR"], file_lines)
        @test haskey(data, "DOPC IMPR")
        PWF._parse_section!(data, "DCTE", sections["DCTE"], file_lines)
        @test haskey(data, "DCTE")
        PWF._parse_section!(data, "DBAR", sections["DBAR"], file_lines)
        @test haskey(data, "DBAR")
        PWF._parse_section!(data, "DLIN", sections["DLIN"], file_lines)
        @test haskey(data, "DLIN")
    end


    @testset "Resulting Dict" begin
        file = open(joinpath(@__DIR__,"data//pwf/test_system.pwf"))
        dict = PWF._parse_pwf_data(file)

        @testset "Keys" begin
            @test haskey(dict, "TITU")
            @test haskey(dict, "DOPC IMPR")
            @test haskey(dict, "DCTE")
            @test haskey(dict, "DBAR")
            @test haskey(dict, "DLIN")
        end

        @testset "Types" begin
            @test isa(dict, Dict)
            @test isa(dict["TITU"], String)
            @test isa(dict["DOPC IMPR"], Dict)
            @test isa(dict["DCTE"], Dict)
            @test isa(dict["DBAR"], Dict)
            @test isa(dict["DLIN"], Dict)
        end

        @testset "Lengths" begin
            @test length(dict["DOPC IMPR"]) == 13
            @test length(dict["DCTE"]) == 67
            @test length(dict["DBAR"]) == 9
            @test length(dict["DLIN"]) == 7

            for (idx,item) in dict["DBAR"]
                @test length(item) == 30
            end
            for (idx,item) in dict["DLIN"]
                @test length(item) == 31
            end
        end

        @testset "DBAR" begin
            for (idx,item) in dict["DBAR"]
                @test isa(item["NUMBER"], Int)
                @test isa(item["OPERATION"], Char)
                @test isa(item["STATUS"], Char)
                @test isa(item["TYPE"], Int)
                @test isa(item["BASE VOLTAGE GROUP"], String)
                @test isa(item["NAME"], String)
                @test isa(item["VOLTAGE LIMIT GROUP"], String)
                @test isa(item["VOLTAGE"], Float64)
                @test isa(item["ANGLE"], Float64)
                @test isa(item["ACTIVE GENERATION"], Float64)
                @test isa(item["REACTIVE GENERATION"], Float64)
                @test isa(item["MINIMUM REACTIVE GENERATION"], Float64)
                @test isa(item["MAXIMUM REACTIVE GENERATION"], Float64)
                @test isa(item["CONTROLLED BUS"], Int)
                @test isa(item["ACTIVE CHARGE"], Float64)
                @test isa(item["REACTIVE CHARGE"], Float64)
                @test isa(item["TOTAL REACTIVE POWER"], Float64)
                @test isa(item["AREA"], Int)
                @test isa(item["CHARGE DEFINITION VOLTAGE"], Float64)
                @test isa(item["VISUALIZATION"], Int)
                @test isa(item["REACTIVE CHARGE"], Float64)
            end
        end

        @testset "DLIN" begin
            for (idx,item) in dict["DLIN"]
                @test isa(item["FROM BUS"], Int)
                @test isa(item["OPENING FROM BUS"], Char)
                @test isa(item["OPERATION"], Char)
                @test isa(item["OPENING TO BUS"], Char)
                @test isa(item["TO BUS"], Int)
                @test isa(item["CIRCUIT"], Int)
                @test isa(item["STATUS"], Char)
                @test isa(item["OWNER"], Char)
                @test isa(item["RESISTANCE"], Float64)
                @test isa(item["REACTANCE"], Float64)
                @test isa(item["SHUNT SUSCEPTANCE"], Float64)
                @test isa(item["TAP"], Nothing) || isa(item["TAP"], Float64)
                @test isa(item["MINIMUM TAP"], Nothing)
                @test isa(item["MAXIMUM TAP"], Nothing)
                @test isa(item["LAG"], Float64)
                @test isa(item["CONTROLLED BUS"], Int)
                @test isa(item["NORMAL CAPACITY"], Float64)
                @test isa(item["EMERGENCY CAPACITY"], Float64)
                @test isa(item["NUMBER OF TAPS"], Int)
                @test isa(item["EQUIPAMENT CAPACITY"], Float64)
                @test isa(item["TRANSFORMER"], Bool)
            end
        end

        @testset "DCTE" begin
            for (key, value) in dict["DCTE"]
                @test isa(key, String)
                @test isa(value, Float64)
                @test length(key) == 4
            end
        end

        @testset "DOPC" begin
            for (key, value) in dict["DOPC IMPR"]
                @test isa(key, String)
                @test isa(value, Char)
                @test length(key) == 4
            end
        end

        @testset "TITU" begin
            @test occursin("Caso do Anderson - P gina 38", dict["TITU"])
        end
    end

    @testset "Default values" begin
        pwf = Dict{String,Any}("TITU" => "Default values test", "name" => "test_defaults",
                               "DCTE" => Dict("TEPA" => 0.1, "TEPR" => 0.1, "TLPR" => 0.1, "TLVC" => .5,
                                            "TLTC" => 0.01, "TETP" => 5.0, "TBPA" => 5.0, "TSFR" => 0.01, "TUDC" => 0.001,
                                            "TADC" => 0.01, "BASE" => 100.0, "DASE" => 100.0, "ZMAX" => 500.0, "ACIT" => 30,
                                            "LPIT" => 50, "LFLP" => 10, "LFIT" => 10, "DCIT" => 10, "VSIT" => 10, "LCRT" => 23,
                                            "LPRT" => 60, "LFCV" => 1, "TPST" => 0.2, "QLST" => 0.2, "EXST" => 0.4, "TLPP" => 1.0,
                                            "TSBZ" => 0.01, "TSBA" => 5.0, "PGER" => 30.0, "VDVN" => 40.0, "VDVM" => 200.0,
                                            "ASTP" => 0.05, "VSTP" => 5.0, "CSTP" => 5.0, "VFLD" => 70, "HIST" => 0, "ZMIN" => 0.001,
                                            "PDIT" => 10, "ICIT" => 50, "FDIV" => 2.0, "DMAX" => 5, "ICMN" => 0.05, "VART" => 5.0,
                                            "TSTP" => 33, "TSDC" => 0.02, "ASDC" => 1, "ICMV" => 0.5, "APAS" => 90, "CPAR" => 70,
                                            "VAVT" => 2.0, "VAVF" => 5.0, "VMVF" => 15.0, "VPVT" => 2.0, "VPVF" => 5.0,
                                            "VPMF" => 10.0, "VSVF" => 20.0, "VINF" => 1.0, "VSUP" => 1.0, "TLSI" => 0.0),
                                "DBAR" => Dict("1" => Dict("NUMBER" => 1, "OPERATION" => 'A', "STATUS" => 'L', "TYPE" => 0, "BASE VOLTAGE GROUP" => " 0", "NAME" => "       Bus 1","VOLTAGE LIMIT GROUP" => " 0", "VOLTAGE" => 1.0, "ANGLE" => 0.0, "ACTIVE GENERATION" => 0.0, "REACTIVE GENERATION" => 0.0, "MINIMUM REACTIVE GENERATION" => 0.0, "MAXIMUM REACTIVE GENERATION" => 0.0, "CONTROLLED BUS" => 1, "ACTIVE CHARGE" => 0.0, "REACTIVE CHARGE" => 0.0, "TOTAL REACTIVE POWER" => 0.0, "AREA" => 1, "CHARGE DEFINITION VOLTAGE" => 1.0, "VISUALIZATION" => 0, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing),
                                               "2" => Dict("NUMBER" => 2, "OPERATION" => 'A', "STATUS" => 'L', "TYPE" => 2, "BASE VOLTAGE GROUP" => " 0", "NAME" => "       Bus 2","VOLTAGE LIMIT GROUP" => " 0", "VOLTAGE" => 1.0, "ANGLE" => 0.0, "ACTIVE GENERATION" => 0.0, "REACTIVE GENERATION" => 0.0, "MINIMUM REACTIVE GENERATION" => -9999.0, "MAXIMUM REACTIVE GENERATION" => 99999.0, "CONTROLLED BUS" => 2, "ACTIVE CHARGE" => 0.0, "REACTIVE CHARGE" => 0.0, "TOTAL REACTIVE POWER" => 0.0, "AREA" => 1, "CHARGE DEFINITION VOLTAGE" => 1.0, "VISUALIZATION" => 0, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing)),
                                "DLIN" => Dict("1" => Dict("FROM BUS" => 1, "OPENING FROM BUS" => 'L', "OPERATION" => 'A', "OPENING TO BUS" => 'L', "TO BUS" => 2, "CIRCUIT" => 0, "STATUS" => 'L', "OWNER" => 'F', "RESISTANCE" => 0.0, "REACTANCE" => nothing, "SHUNT SUSCEPTANCE" => 0.0, "TAP" => 1.0, "MINIMUM TAP" => 0.95, "MAXIMUM TAP" => 1.05, "LAG" => 0.0, "CONTROLLED BUS" => 1, "NORMAL CAPACITY" => Inf, "EMERGENCY CAPACITY" => Inf, "NUMBER OF TAPS" => 33, "EQUIPAMENT CAPACITY" => Inf, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing, "TRANSFORMER" => true),
                                               "2" => Dict("FROM BUS" => 2, "OPENING FROM BUS" => 'L', "OPERATION" => 'A', "OPENING TO BUS" => 'L', "TO BUS" => 1, "CIRCUIT" => 0, "STATUS" => 'L', "OWNER" => 'F', "RESISTANCE" => 0.0, "REACTANCE" => nothing, "SHUNT SUSCEPTANCE" => 0.0, "TAP" => 1.0, "MINIMUM TAP" => nothing, "MAXIMUM TAP" => nothing, "LAG" => 0.0, "CONTROLLED BUS" => 2, "NORMAL CAPACITY" => 0.0, "EMERGENCY CAPACITY" => 0.0, "NUMBER OF TAPS" => 33, "EQUIPAMENT CAPACITY" => 0.0, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing, "TRANSFORMER" => false)),
                                "DGER" => Dict("1" => Dict("NUMBER" => 1, "OPERATION" => 'A', "MINIMUM ACTIVE GENERATION" => 0.0, "MAXIMUM ACTIVE GENERATION" => 99999.0, "PARTICIPATION FACTOR" => 0.0, "REMOTE CONTROL PARTICIPATION FACTOR" => 100., "NOMINAL POWER FACTOR" => nothing, "ARMATURE SERVICE FACTOR" => nothing,"ROTOR SERVICE FACTOR" => nothing, "CHARGE ANGLE" => nothing, "MACHINE REACTANCE" => nothing, "NOMINAL APPARENT POWER" => nothing)),
                                "DGBT" => Dict("1" => Dict("GROUP" => " 0", "VOLTAGE" => 1.0)),
                                "DGLT" => Dict("1" => Dict("GROUP" => " 0", "LOWER BOUND" => 0.8, "UPPER BOUND" => 1.2, "LOWER EMERGENCY BOUND" => 0.8, "UPPER EMERGENCY BOUND" => 1.2), "2" => Dict("GROUP" => " 1", "LOWER BOUND" => 0.9, "UPPER BOUND" => 1.1, "LOWER EMERGENCY BOUND" => 0.9, "UPPER EMERGENCY BOUND" => 1.1)),
                                "DCBA" => Dict("1" => Dict("NUMBER" => 10, "OPERATION" => 'A', "TYPE" => 1, "POLARITY" => '+', "NAME" => "RET         ", "VOLTAGE LIMIT GROUP" => " 0", "VOLTAGE" => 1.0, "GROUND ELECTRODE" => 0.0, "DC LINK" => 1),
                                               "2" => Dict("NUMBER" => 20, "OPERATION" => 'A', "TYPE" => 0, "POLARITY" => '-', "NAME" => "INV         ", "VOLTAGE LIMIT GROUP" => " 0", "VOLTAGE" => 1.0, "GROUND ELECTRODE" => 0.0, "DC LINK" => 1),
                                               "3" => Dict("NUMBER" => 30, "OPERATION" => 'A', "TYPE" => 0, "POLARITY" => '0', "NAME" => "NEUR        ", "VOLTAGE LIMIT GROUP" => " 0", "VOLTAGE" => 0.0, "GROUND ELECTRODE" => 0.0, "DC LINK" => 1),
                                               "4" => Dict("NUMBER" => 40, "OPERATION" => 'A', "TYPE" => 0, "POLARITY" => '0', "NAME" => "NEUI        ", "VOLTAGE LIMIT GROUP" => " 0", "VOLTAGE" => 0.0, "GROUND ELECTRODE" => 0.0, "DC LINK" => 1)),
                                "DCLI" => Dict("1" => Dict("FROM BUS" => 10, "OPERATION" => 'A', "TO BUS" => 20, "CIRCUIT" => 0, "OWNER" => nothing, "RESISTANCE" => nothing, "INDUCTANCE" => 0.0, "CAPACITY" => Inf)),
                                "DELO" => Dict("1" => Dict("NUMBER" => 1, "OPERATION" => 'A', "VOLTAGE" => nothing, "BASE" => 100.0, "NAME" => nothing, "HI MVAR MODE" => 'N', "STATUS" => 'L')),
                                "DBSH" => Dict("1" => Dict("FROM BUS" => 1, "OPERATION" => 'A', "TO BUS" => nothing, "CIRCUIT" => 1, "CONTROL MODE" => 'C', "MINIMUM VOLTAGE" => 0.8, "MAXIMUM VOLTAGE" => 1.2, "CONTROLLED BUS" => 1, "INITIAL REACTIVE INJECTION" => 0.0, "CONTROL TYPE" => 'C', "ERASE DBAR" => 'N', "EXTREMITY" => nothing, "REACTANCE GROUPS" => Dict("1" => Dict("GROUP" => 10, "OPERATION" => 'A', "STATUS" => 'L', "UNITIES" => 1, "OPERATING UNITIES" => 1, "REACTANCE" => nothing), "2" => Dict("GROUP" => 20, "OPERATION" => 'A', "STATUS" => 'L', "UNITIES" => 2, "OPERATING UNITIES" => 2, "REACTANCE" => nothing)))),
                                "DCSC" => Dict("1" => Dict("FROM BUS" => 1, "OPERATION" => 'A', "TO BUS" => 2, "CIRCUIT" => 0, "STATUS" => 'L', "OWNER" => 'F', "BYPASS" => 'D', "MINIMUM VALUE" => -9999.0, "MAXIMUM VALUE" => 0.0, "INITIAL VALUE" => 0.0, "CONTROL MODE" => 'X', "SPECIFIED VALUE" => nothing, "MEASUREMENT EXTREMITY" => 1, "NUMBER OF STAGES" => nothing, "NORMAL CAPACITY" => Inf, "EMERGENCY CAPACITY" => Inf, "EQUIPAMENT CAPACITY" => Inf, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing)),
                                "DCAI" => Dict("1" => Dict("BUS" => 1, "OPERATION" => 'A', "GROUP" => nothing, "STATUS" => 'L', "UNITIES" => 2, "OPERATING UNITIES" => 2, "ACTIVE CHARGE" => 0.0, "REACTIVE CHARGE" => 0.0, "PARAMETER A" => nothing, "PARAMETER B" => nothing, "PARAMETER C" => nothing, "PARAMETER D" => nothing, "VOLTAGE" => 70.0, "CHARGE DEFINITION VOLTAGE" => 1.0)),
                                "DGEI" => Dict("1" => Dict("BUS" => 1, "OPERATION" => 'A', "AUTOMATIC MODE" => 'N', "GROUP" => nothing, "STATUS" => 'L', "UNITIES" => 2, "OPERATING UNITIES" => 2, "MINIMUM OPERATING UNITIES" => 1, "ACTIVE GENERATION" => 0.0, "REACTIVE GENERATION" => 0.0, "MINIMUM REACTIVE GENERATION" => -9999.0, "MAXIMUM REACTIVE GENERATION" => 99999.0, "ELEVATOR TRANSFORMER REACTANCE" => nothing, "XD" => 0.0, "XQ" => 0.0, "XL" => 0.0, "POWER FACTOR" => 1.0, "APPARENT POWER" => 99999.0, "MECHANICAL LIMIT" => 99999.0)))
        parsed_pwf = PWF.parse_file(joinpath(@__DIR__,"data/pwf/test_defaults.pwf"), pm = false)

        @test parsed_pwf == pwf
    end
end