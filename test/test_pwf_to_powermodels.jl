@testset "Dict to PowerModels" begin
    @testset "PowerModels Dict fields" begin
        @testset "PowerModels conversion" begin
            file = open(joinpath(@__DIR__,"data/pwf/test_system.pwf"))
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
                    @test haskey(bus, "control_data")
                    @test haskey(bus["control_data"], "voltage_controlled_bus")

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
                    @test isa(bus["control_data"], Dict)
                    @test isa(bus["control_data"]["voltage_controlled_bus"], Int)
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
                    @test haskey(branch, "control_data")

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
                    @test isa(branch["control_data"], Dict)
                end

            end

            @testset "DCline" begin
                pwf_dc = open(joinpath(@__DIR__,"data/pwf/300bus.pwf"))
                pwf_data_dc = ParserPWF.parse_pwf_to_powermodels(pwf_dc)

                @test haskey(pwf_data_dc, "dcline")
                @test length(pwf_data_dc["dcline"]) == 1
                @test pwf_data_dc["dcline"]["1"]["pf"] == 1.0
                @test isapprox(pwf_data_dc["dcline"]["1"]["pt"], -0.99707, atol = 1e-4)
                @test pwf_data_dc["dcline"]["1"]["vf"] == 1.044
                @test pwf_data_dc["dcline"]["1"]["vt"] == 0.998
            end

        end

        @testset "Resulting Dict" begin
            file = open(joinpath(@__DIR__,"data/pwf/test_system.pwf"))
            pm_data = ParserPWF.parse_pwf_to_powermodels(file; software = ParserPWF.Organon)

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
                result = optimize_model!(pm, optimizer=ipopt)

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
                file_raw = joinpath(@__DIR__,"data/raw/$name.raw")
                file_pwf = open(joinpath(@__DIR__,"data/pwf/$name.pwf"))
            
                pwf_data = ParserPWF.parse_pwf_to_powermodels(file_pwf)
                raw_data = PowerModels.parse_file(file_raw)
                
                result_pwf = PowerModels.run_ac_pf(pwf_data, ipopt)
                result_raw = PowerModels.run_ac_pf(raw_data, ipopt)
                
                @test check_same_dict(result_pwf["solution"], result_raw["solution"], atol = 10e-9)
            end
        
        end

        @testset "PWF to PM corrections" begin
            file = open(joinpath(@__DIR__,"data/pwf/3bus_corrections.pwf"))
            pm_data = ParserPWF.parse_pwf_to_powermodels(file; software = ParserPWF.Organon)

            parse_result = PowerModels.run_ac_pf(pm_data, ipopt);

            result = Dict(
                "1" => Dict("va" => 0, "vm" => 1.029),
                "2" => Dict("va" => -0.0171315, "vm" => 1.03),
                "3" => Dict("va" => -0.02834, "vm" => 0.999)
            );
            @test check_same_dict(parse_result["solution"]["bus"], result)
        end
    end

    @testset "Control data fields" begin
        @testset "Shunt control_data" begin
            file = open(joinpath(@__DIR__,"data/pwf/3bus_shunt_fields.pwf"))
            pm_data = ParserPWF.parse_pwf_to_powermodels(file, software = ParserPWF.ANAREDE)

            @test length(pm_data["bus"]) == 3
            @test occursin("B s 1", pm_data["bus"]["1"]["name"])
            @test pm_data["bus"]["2"]["control_data"]["voltage_controlled_bus"] == 3

            @test length(pm_data["shunt"]) == 3
            
            @test pm_data["shunt"]["1"]["control_data"]["shunt_type"] == 1
            @test pm_data["shunt"]["1"]["control_data"]["shunt_control_type"] == 1
            @test pm_data["shunt"]["1"]["control_data"]["bsmin"] == -0.1
            @test pm_data["shunt"]["1"]["control_data"]["bsmax"] == -0.1
            @test pm_data["shunt"]["1"]["control_data"]["controlled_bus"] == 3
            @test pm_data["shunt"]["1"]["control_data"]["vmmin"] == 1.03
            @test pm_data["shunt"]["1"]["control_data"]["vmmax"] == 1.03
            @test pm_data["shunt"]["1"]["control_data"]["inclination"] == nothing

            @test pm_data["shunt"]["2"]["control_data"]["shunt_type"] == 2
            @test pm_data["shunt"]["2"]["control_data"]["shunt_control_type"] == 3
            @test pm_data["shunt"]["2"]["control_data"]["bsmin"] == -0.5
            @test pm_data["shunt"]["2"]["control_data"]["bsmax"] == 1.
            @test pm_data["shunt"]["2"]["control_data"]["controlled_bus"] == 1
            @test pm_data["shunt"]["2"]["control_data"]["vmmin"] == 1.029
            @test pm_data["shunt"]["2"]["control_data"]["vmmax"] == 1.029
            @test pm_data["shunt"]["2"]["control_data"]["inclination"] == 2.0

            @test pm_data["shunt"]["3"]["control_data"]["shunt_type"] == 2
            @test pm_data["shunt"]["3"]["control_data"]["shunt_control_type"] == 2
            @test pm_data["shunt"]["3"]["control_data"]["bsmin"] == -0.3
            @test pm_data["shunt"]["3"]["control_data"]["bsmax"] == 0.6
            @test pm_data["shunt"]["3"]["control_data"]["controlled_bus"] == 72
            @test pm_data["shunt"]["3"]["control_data"]["vmmin"] == 0.9
            @test pm_data["shunt"]["3"]["control_data"]["vmmax"] == 1.1
            @test pm_data["shunt"]["3"]["control_data"]["inclination"] == nothing

        end

        @testset "Line shunt" begin
            file = open(joinpath(@__DIR__,"data/pwf/test_line_shunt.pwf"))
            pm_data = ParserPWF.parse_pwf_to_powermodels(file; software = ParserPWF.Organon)

            @test pm_data["branch"]["1"]["b_fr"] == 4.5
            @test pm_data["branch"]["1"]["b_to"] == 7.8
            @test pm_data["branch"]["2"]["b_fr"] == -80
            @test pm_data["branch"]["2"]["b_to"] == -0.07
            @test pm_data["branch"]["3"]["b_fr"] == 0.0
            @test pm_data["branch"]["3"]["b_to"] == 0.0
            @test length(pm_data["shunt"]) == 1
            @test pm_data["shunt"]["1"]["bs"] == -1.755
        end

        @testset "Transformer control fields" begin
            data = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/9bus_transformer_fields.pwf"))

            tap_automatic_control = findfirst(x -> x["f_bus"] == 1 && x["t_bus"] == 4, data["branch"])
            tap_variable_control = findfirst(x -> x["f_bus"] == 2 && x["t_bus"] == 7, data["branch"])
            phase_control = findfirst(x -> x["f_bus"] == 3 && x["t_bus"] == 9, data["branch"])

            tap_automatic_control = data["branch"][tap_automatic_control]["control_data"]
            tap_variable_control = data["branch"][tap_variable_control]["control_data"]
            phase_control = data["branch"][phase_control]["control_data"]

            @test tap_automatic_control["control_type"] == "tap_control"
            @test tap_automatic_control["constraint_type"] == "setpoint"
            @test tap_automatic_control["controlled_bus"] == 1
            @test tap_automatic_control["tapmin"] == 0.85
            @test tap_automatic_control["tapmax"] == 1.15
            @test tap_automatic_control["vmsp"] == 1.075
            @test tap_automatic_control["vmmin"] == 0.9
            @test tap_automatic_control["vmmax"] == 1.1
            @test tap_automatic_control["shift_control_variable"] == nothing
            @test tap_automatic_control["shiftmin"] == nothing
            @test tap_automatic_control["shiftmax"] == nothing
            @test tap_automatic_control["valsp"] == nothing
            @test tap_automatic_control["circuit"] == 1
            @test tap_automatic_control["control"] == false

            @test tap_variable_control["control_type"] == "tap_control"
            @test tap_variable_control["constraint_type"] == "bounds"
            @test tap_variable_control["controlled_bus"] == 7
            @test tap_variable_control["tapmin"] == 0.85
            @test tap_variable_control["tapmax"] == 1.15
            @test tap_variable_control["vmsp"] == 1.078
            @test tap_variable_control["vmmin"] == 0.8
            @test tap_variable_control["vmmax"] == 1.2
            @test tap_variable_control["shift_control_variable"] == nothing
            @test tap_variable_control["shiftmin"] == nothing
            @test tap_variable_control["shiftmax"] == nothing
            @test tap_variable_control["valsp"] == 100.0
            @test tap_variable_control["circuit"] == 1
            @test tap_variable_control["control"] == true

            @test phase_control["control_type"] == "shift_control"
            @test phase_control["constraint_type"] == "setpoint"
            @test phase_control["controlled_bus"] == 9
            @test phase_control["tapmin"] == nothing
            @test phase_control["tapmax"] == nothing
            @test phase_control["vmsp"] == 1.083
            @test phase_control["vmmin"] == 0.8
            @test phase_control["vmmax"] == 1.2
            @test phase_control["shift_control_variable"] == "power"
            @test isapprox(phase_control["shiftmin"], -0.523598775; atol = 1e-5)
            @test isapprox(phase_control["shiftmin"],  0.523598775; atol = 1e-5)
            @test phase_control["valsp"] == 2.505
            @test phase_control["circuit"] == 1
            @test phase_control["control"] == true
        end
    end

    @testset "Organon vs ANAREDE parser" begin
        @testset "DBSH" begin
            data_anarede = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DBSH.pwf"), software = ParserPWF.ANAREDE)
            data_organon = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DBSH.pwf"), software = ParserPWF.Organon)

            pm_anarede = PowerModels.instantiate_model(data_anarede, PowerModels.ACPPowerModel, PowerModels.build_pf);
            pm_organon = PowerModels.instantiate_model(data_organon, PowerModels.ACPPowerModel, PowerModels.build_pf);

            result_anarede = PowerModels.optimize_model!(pm_anarede, optimizer = ipopt)
            result_organon = PowerModels.optimize_model!(pm_organon, optimizer = ipopt)

            PowerModels.update_data!(data_anarede, result_anarede["solution"])
            PowerModels.update_data!(data_organon, result_organon["solution"])

            @test isapprox(data_anarede["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["2"]["vm"], 1.03, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["3"]["vm"], 0.960, atol = 1e-3)

            @test isapprox(data_anarede["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["2"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["3"]["va"], 0.8*pi/180, atol = 1e-1)

            @test isapprox(data_anarede["gen"]["1"]["pg"], 0.162, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["pg"], 0.171, atol = 1e-3)

            @test isapprox(data_anarede["gen"]["1"]["qg"], 0.233, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["qg"], 0.242, atol = 1e-3)
        end

        @testset "DCER" begin
            data_anarede = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DCER.pwf"), software = ParserPWF.ANAREDE)
            data_organon = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DCER.pwf"), software = ParserPWF.Organon)

            pm_anarede = PowerModels.instantiate_model(data_anarede, PowerModels.ACPPowerModel, PowerModels.build_pf);
            pm_organon = PowerModels.instantiate_model(data_organon, PowerModels.ACPPowerModel, PowerModels.build_pf);

            result_anarede = PowerModels.optimize_model!(pm_anarede, optimizer = ipopt)
            result_organon = PowerModels.optimize_model!(pm_organon, optimizer = ipopt)

            PowerModels.update_data!(data_anarede, result_anarede["solution"])
            PowerModels.update_data!(data_organon, result_organon["solution"])

            @test isapprox(data_anarede["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["2"]["vm"], 1.03, atol = 1e-3)
            # @test isapprox(data_anarede["bus"]["3"]["vm"], 1.024, atol = 1e-3)

            @test isapprox(data_anarede["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["2"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["3"]["va"], -2.7*pi/180, atol = 1e-1)

            # DCER implicates ANAREDE control, which can't be replicated in PowerModels
            # @test isapprox(data_anarede["gen"]["1"]["pg"], 0.154, atol = 1e-3)
            # @test isapprox(data_anarede["gen"]["2"]["pg"], 0.163, atol = 1e-3)

            # @test isapprox(data_anarede["gen"]["1"]["qg"], -0.129, atol = 1e-3)
            # @test isapprox(data_anarede["gen"]["2"]["qg"], -0.120, atol = 1e-3)
        end

        @testset "DSHL" begin
            data_anarede = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DSHL.pwf"), software = ParserPWF.ANAREDE)
            data_organon = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DSHL.pwf"), software = ParserPWF.Organon)

            pm_anarede = PowerModels.instantiate_model(data_anarede, PowerModels.ACPPowerModel, PowerModels.build_pf);
            pm_organon = PowerModels.instantiate_model(data_organon, PowerModels.ACPPowerModel, PowerModels.build_pf);

            result_anarede = PowerModels.optimize_model!(pm_anarede, optimizer = ipopt)
            result_organon = PowerModels.optimize_model!(pm_organon, optimizer = ipopt)

            PowerModels.update_data!(data_anarede, result_anarede["solution"])
            PowerModels.update_data!(data_organon, result_organon["solution"])

            @test isapprox(data_anarede["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["2"]["vm"], 0.662, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["3"]["vm"], 0.695, atol = 1e-3)

            @test isapprox(data_anarede["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["2"]["va"], 19*pi/180, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["3"]["va"], 11.8*pi/180, atol = 1e-1)

            @test isapprox(data_anarede["gen"]["1"]["pg"], 1.205, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["pg"], 0.130, atol = 1e-3)

            @test isapprox(data_anarede["gen"]["1"]["qg"], 3.191, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["qg"], 0.025, atol = 1e-3)
            
            @test isapprox(data_organon["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            
            # Organon performs automatic controls that can't be replicated in PowerModels
            # @test isapprox(data_organon["bus"]["2"]["vm"], 0.665, atol = 1e-3)
            # @test isapprox(data_organon["bus"]["3"]["vm"], 0.705, atol = 1e-3)

            @test isapprox(data_organon["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_organon["bus"]["2"]["va"], 19.34*pi/180, atol = 1e-2)
            # @test isapprox(data_organon["bus"]["3"]["va"], 12.51*pi/180, atol = 1e-2)

            # @test isapprox(data_organon["gen"]["1"]["pg"], 1.131, atol = 1e-3)
            @test isapprox(data_organon["gen"]["2"]["pg"], 0.130, atol = 1e-3)

            # @test isapprox(data_organon["gen"]["1"]["qg"], 3.209, atol = 1e-3)
            @test isapprox(data_organon["gen"]["2"]["qg"], 0.025, atol = 1e-3)
        end

        @testset "DCSC" begin
            data_anarede = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DCSC.pwf"), software = ParserPWF.ANAREDE)
            data_organon = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DCSC.pwf"), software = ParserPWF.Organon)

            pm_anarede = PowerModels.instantiate_model(data_anarede, PowerModels.ACPPowerModel, PowerModels.build_pf);
            pm_organon = PowerModels.instantiate_model(data_organon, PowerModels.ACPPowerModel, PowerModels.build_pf);

            result_anarede = PowerModels.optimize_model!(pm_anarede, optimizer = ipopt)
            result_organon = PowerModels.optimize_model!(pm_organon, optimizer = ipopt)

            PowerModels.update_data!(data_anarede, result_anarede["solution"])
            PowerModels.update_data!(data_organon, result_organon["solution"])

            @test isapprox(data_anarede["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["2"]["vm"], 1.030, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["3"]["vm"], 1.030, atol = 1e-3)

            @test isapprox(data_anarede["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["2"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["3"]["va"], -1.8*pi/180, atol = 1e-1)

            @test isapprox(data_anarede["gen"]["1"]["pg"], 0.088, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["pg"], 0.091, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["3"]["pg"], 0.130, atol = 1e-3)

            @test isapprox(data_anarede["gen"]["1"]["qg"], 0.067, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["qg"], -0.254, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["3"]["qg"], 0.246, atol = 1e-3)
            
            @test isapprox(data_organon["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            @test isapprox(data_organon["bus"]["2"]["vm"], 1.030, atol = 1e-3)
            @test isapprox(data_organon["bus"]["3"]["vm"], 1.011, atol = 1e-3)

            @test isapprox(data_organon["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_organon["bus"]["2"]["va"], 0.0, atol = 1e-2)
            @test isapprox(data_organon["bus"]["3"]["va"], -0.69*pi/180, atol = 1e-2)

            @test isapprox(data_organon["gen"]["1"]["pg"], 0.087, atol = 1e-3)
            @test isapprox(data_organon["gen"]["2"]["pg"], 0.090, atol = 1e-3)
            @test isapprox(data_organon["gen"]["3"]["pg"], 0.130, atol = 1e-3)

            @test isapprox(data_organon["gen"]["1"]["qg"], 0.176, atol = 1e-3)
            @test isapprox(data_organon["gen"]["2"]["qg"], -0.145, atol = 1e-3)
            @test isapprox(data_organon["gen"]["3"]["qg"], 0.025, atol = 1e-3)
        end

        @testset "DC line" begin
            data_anarede = ParserPWF.parse_pwf_to_powermodels(joinpath(@__DIR__,"data/pwf/3bus_DCline.pwf"), software = ParserPWF.ANAREDE)
            pm_anarede = PowerModels.instantiate_model(data_anarede, PowerModels.ACPPowerModel, PowerModels.build_pf);
            result_anarede = PowerModels.optimize_model!(pm_anarede, optimizer = ipopt)
            PowerModels.update_data!(data_anarede, result_anarede["solution"])

            @test isapprox(data_anarede["bus"]["1"]["vm"], 1.029, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["2"]["vm"], 1.030, atol = 1e-3)
            @test isapprox(data_anarede["bus"]["3"]["vm"], 0.997, atol = 1e-3)

            @test isapprox(data_anarede["bus"]["1"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["2"]["va"], 0.0, atol = 1e-1)
            @test isapprox(data_anarede["bus"]["3"]["va"], -1.2*pi/180, atol = 1e-1)

            @test isapprox(data_anarede["gen"]["1"]["pg"], 6.405, atol = 1e-3)
            @test isapprox(data_anarede["gen"]["2"]["pg"], -5.979, atol = 1e-3)

            # PowerModels' DC line model can't replicate exactly ANAREDE's
            # @test isapprox(data_anarede["gen"]["1"]["qg"], 2.503, atol = 1e-3)
            # @test isapprox(data_anarede["gen"]["2"]["qg"], 2.605, atol = 1e-3)

            @test isapprox(data_anarede["dcline"]["1"]["pf"], 6.250, atol = 1e-3)
            @test isapprox(data_anarede["dcline"]["1"]["pt"], -6.136, atol = 1e-3)
            # @test isapprox(data_anarede["dcline"]["1"]["qf"], 2.473, atol = 1e-3)
            # @test isapprox(data_anarede["dcline"]["1"]["qt"], 2.573, atol = 1e-3)
        end
    end
end
