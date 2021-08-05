using Test, PowerModels, Ipopt

include("src/ParsePWF.jl")

@testset "Test functions" begin
    include("test/test_pwf.jl")
end
