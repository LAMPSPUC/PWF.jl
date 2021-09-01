using Test, PowerModels, Ipopt

include("src/ParserPWF.jl")

@testset "Test functions" begin
    include("test/test_functions.jl")
    include("test/test_pwf.jl")
end
