using DateSelectors
using Dates
using Intervals
using Random
using Test

Random.seed!(1)

@testset "DateSelectors.jl" begin
    include("common.jl")
    include("NoneSelector.jl")
    include("PeriodicSelector.jl")
    include("RandomSelector.jl")

    include("sensibility_checks.jl")
end
