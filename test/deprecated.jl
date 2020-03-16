@testset "deprecated.jl" begin

    @test_deprecated RandomSelector(5, nothing, Random.GLOBAL_RNG)
    @test_deprecated RandomSelector(5, 1, nothing, Random.GLOBAL_RNG)

end
