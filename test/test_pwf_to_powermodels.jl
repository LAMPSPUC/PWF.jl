@testset "Dict to PowerModels" begin
    @testset "Intermediary functions" begin
        file = open(joinpath(@__DIR__,"data/test_system.pwf"))
        pwf_data = ParserPWF._parse_pwf_data(file)
        pm_data = Dict{String, Any}()

        @testset "Bus" begin
            ParserPWF._pwf2pm_bus!(pm_data, pwf_data)
            
            @test haskey(pm_data, "bus")
            @test length(pm_data["bus"]) == 9

            for (idx, bus) in pm_data["bus"]
                @test haskey(bus, "zone")
                @test haskey(bus, "bus_i")
                @test haskey(bus, "bus_type")
                @test haskey(bus, "name")
                @test haskey(bus, "vmax")
                @test haskey(bus, "source_id")
                @test haskey(bus, "area")
                @test haskey(bus, "vmin")
                @test haskey(bus, "index")
                @test haskey(bus, "va")
                @test haskey(bus, "vm")
                @test haskey(bus, "base_kv")

                @test isa(bus["zone"], Int)
                @test isa(bus["bus_i"], Int)
                @test isa(bus["bus_type"], Int)
                @test isa(bus["name"], String)
                @test isa(bus["vmax"], Float64)
                @test isa(bus["source_id"], Vector)
                @test isa(bus["area"], Int)
                @test isa(bus["vmin"], Float64)
                @test isa(bus["index"], Int)
                @test isa(bus["va"], Float64)
                @test isa(bus["vm"], Float64)
                @test isa(bus["base_kv"], Float64)
            end
        end

        @testset "Branch" begin
            ParserPWF._pwf2pm_branch!(pm_data, pwf_data)
            ParserPWF._pwf2pm_transformer!(pm_data, pwf_data)
            
            @test haskey(pm_data, "branch")
            @test length(pm_data["branch"]) == 7

            for (idx, branch) in pm_data["branch"]
                @test haskey(branch, "br_r")
                @test haskey(branch, "shift")
                @test haskey(branch, "br_x")
                @test haskey(branch, "g_to")
                @test haskey(branch, "g_fr")
                @test haskey(branch, "b_fr")
                @test haskey(branch, "source_id")
                @test haskey(branch, "f_bus")
                @test haskey(branch, "br_status")
                @test haskey(branch, "t_bus")
                @test haskey(branch, "b_to")
                @test haskey(branch, "index")
                @test haskey(branch, "angmin")
                @test haskey(branch, "angmax")
                @test haskey(branch, "transformer")
                @test haskey(branch, "tap")

                @test isa(branch["br_r"], Float64)
                @test isa(branch["shift"], Float64)
                @test isa(branch["br_x"], Float64)
                @test isa(branch["g_to"], Float64)
                @test isa(branch["g_fr"], Float64)
                @test isa(branch["b_fr"], Float64)
                @test isa(branch["source_id"], Vector)
                @test isa(branch["f_bus"], Int)
                @test isa(branch["br_status"], Int)
                @test isa(branch["t_bus"], Int)
                @test isa(branch["b_to"], Float64)
                @test isa(branch["index"], Int)
                @test isa(branch["angmin"], Float64)
                @test isa(branch["angmax"], Float64)
                @test isa(branch["transformer"], Bool)
                @test isa(branch["tap"], Float64)
            end

        end

        @testset "DCline" begin

            pwf_dc = open(joinpath(@__DIR__,"data/300bus.pwf"))
            pwf_data_dc = ParserPWF.parse_pwf_to_powermodels(pwf_dc)

            @test haskey(pwf_data_dc, "dcline")
            @test length(pwf_data_dc["dcline"]) == 1

            raw_dc = joinpath(@__DIR__,"data/300bus.raw")
            raw_data_dc = PowerModels.parse_file(raw_dc)

            @test check_same_dict(pwf_data_dc, raw_data_dc, "dcline")   
                
        end

    end

    @testset "Resulting Dict" begin
        file = open(joinpath(@__DIR__,"data/test_system.pwf"))
        pm_data = ParserPWF.parse_pwf_to_powermodels(file)

        @testset "PowerModels Dict" begin
            @test isa(pm_data, Dict)

            @test haskey(pm_data, "name")
            @test haskey(pm_data, "source_version")
            @test haskey(pm_data, "baseMVA")
            @test haskey(pm_data, "branch")
            @test haskey(pm_data, "bus")
            @test haskey(pm_data, "per_unit")
            @test haskey(pm_data, "source_type")

            @test isa(pm_data["name"], AbstractString)
            @test isa(pm_data["source_version"], String)
            @test isa(pm_data["baseMVA"], Float64)
            @test isa(pm_data["branch"], Dict)
            @test isa(pm_data["bus"], Dict)
            @test isa(pm_data["per_unit"], Bool)
            @test isa(pm_data["source_type"], String)
        end

        @testset "Power Flow" begin

            pm = instantiate_model(pm_data, ACPPowerModel, PowerModels.build_pf)
            result = optimize_model!(pm, optimizer=Ipopt.Optimizer)

            @testset "Status" begin
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["dual_status"]        == FEASIBLE_POINT
                @test result["primal_status"]      == FEASIBLE_POINT
            end

            @testset "Result" begin
                solution = result["solution"]

                @test solution["baseMVA"]             == 100.0
                @test solution["multiinfrastructure"] == false
                @test solution["multinetwork"]        == false
                @test solution["per_unit"]            == true
                @test length(solution["bus"])         == 9
            end

        end

    end

    @testset "Power Flow results" begin
        filenames = ["3bus", "9bus"]

        for name in filenames
            file_raw = joinpath(@__DIR__,"data/$name.raw")
            file_pwf = open(joinpath(@__DIR__,"data/$name.pwf"))
        
            pwf_data = ParserPWF.parse_pwf_to_powermodels(file_pwf)
            raw_data = PowerModels.parse_file(file_raw)

            solver = optimizer_with_attributes(
                Ipopt.Optimizer, 
                "print_level"=>0,
            )
            result_pwf = PowerModels.run_ac_pf(pwf_data, solver)
            result_raw = PowerModels.run_ac_pf(raw_data, solver)
            
            @test check_same_dict(result_pwf["solution"], result_raw["solution"], atol = 10e-9)
        end
    
    end

end