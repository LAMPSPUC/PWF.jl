using Ipopt
using Test
using PowerModels

include("../src/ParserPWF.jl")

include("test_functions.jl")

ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 0.0001, "print_level" => 0)

@testset "ParserPWF" begin
    include("test_pwf.jl")
    include("test_pwf_to_powermodels.jl")
end