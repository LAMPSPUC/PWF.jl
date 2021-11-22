using Ipopt
using Test
using PowerModels

include("../src/PWF.jl")

include("test_functions.jl")

ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 0.0001, "print_level" => 0)

@testset "PWF" begin
    include("test_pwf.jl")
    include("test_pwf_to_powermodels.jl")
end