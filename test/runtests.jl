using Test
using JuliOpt

@testset "JuliOpt" begin
    include("knapsack_test.jl")
    include("bin_packing_test.jl")
    include("interval_scheduling_test.jl")
end
