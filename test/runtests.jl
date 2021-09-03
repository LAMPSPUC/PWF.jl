using Ipopt
using Test
using PowerModels

include("../src/ParserPWF.jl")

@testset "Test functions" begin
    include("test_functions.jl")
    include("test_pwf.jl")
end
