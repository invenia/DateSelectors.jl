using DateSelectors
using Dates
using Random
using StatsBase: Weights
using Test

@testset "DateSelectors.jl" begin
    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)

    @testset "Periodic" begin
        selector = PeriodicSelector(Week(1))
        @test selector isa DateSelector

        result = partition(selector, st, ed)
        @test result isa NamedTuple{(:holdout, :validation),Tuple{Vector{Date}, Vector{Date}}}
        holdout, validation = result
        @test sort(vcat(validation, holdout)) == collect(st:Day(1):ed)

        @test all(in(st:Day(1):ed), holdout)
        @test length(holdout) == 5

        expected = [st:Week(1):ed...]
        @test holdout == expected
        @test holdout == first(partition(selector, st:Day(1):ed))

        selector = PeriodicSelector(Day(2))

        result, _ = partition(selector, st, ed)
        @test all(in(st:Day(1):ed), result)
        @test length(result) == 16

        expected = [st:Day(2):ed...]
        @test result == expected

        @testset "Offset" begin
            selector = PeriodicSelector(Week(1), Day(1), Day(1))

            result, _ = partition(selector, st, ed)
            @test all(in(st:Day(1):ed), result)
            @test length(result) == 5

            expected = [st+Day(1):Week(1):ed...]
            @test result == expected
        end

        @testset "BiWeekly" begin
            selector = PeriodicSelector(Week(2), Week(1))

            result, _ = partition(selector, st, ed)
            @test all(in(st:Day(1):ed), result)
            @test length(result) == 14

            expected = [st:Day(1):st+Day(6)..., st+Day(14):Day(1):st+Day(20)...]
            @test result == expected
        end
    end

    @testset "Random" begin
        selector = RandomSelector(10)
        @test selector isa DateSelector

        result = partition(selector, st, ed)
        @test result isa NamedTuple{(:holdout, :validation),Tuple{Vector{Date}, Vector{Date}}}
        holdout, validation = result
        @test sort(vcat(validation, holdout)) == collect(st:Day(1):ed)

        @test all(in(st:Day(1):ed), holdout)
        @test length(holdout) == 10

        result = partition(selector, st:Day(1):ed)
        @test result isa NamedTuple{(:holdout, :validation),Tuple{Vector{Date}, Vector{Date}}}
        @test length(first(result)) == 10

        @test_throws ErrorException partition(RandomSelector(50), st, ed)

        holdout, validation = partition(RandomSelector(32), st, ed)
        @test length(unique(holdout)) == 32
        @test length(validation) == 0

        @testset "Seed" begin
            result = partition(RandomSelector(3, 1), st, ed)
            @test result == partition(RandomSelector(3, nothing, Random.seed!(1)), st, ed)
            @test first(result) == [Date(2019, 1, 15), Date(2019, 1, 4), Date(2019, 1, 10)]
        end

        @testset "Weights" begin
            wv = Weights([zeros(29); 1:3])
            result, _ = partition(RandomSelector(3, 1, wv), st, ed)
            @test result == [Date(2019, 2, 1), Date(2019, 1, 31), Date(2019, 1, 30)]
        end
    end

    @testset "None" begin
        selector = NoneSelector()
        @test selector isa DateSelector

        result = partition(selector, st, ed)
        @test result isa NamedTuple{(:holdout, :validation),Tuple{Vector{Date}, Vector{Date}}}
        holdout, validation = result
        @test validation == collect(st:Day(1):ed)
        @test length(holdout) == 0
    end
end
