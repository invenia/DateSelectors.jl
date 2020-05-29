@testset "RandomSelector" begin
    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)
    date_range = st:Day(1):ed
    
    @testset "construction" begin
        wv = Weights([zeros(29); 1:3])

        selector = RandomSelector(10, 2)
        @test selector.holdout_blocks == 10
        @test selector.block_size == 1
        @test selector.seed == 2
        @test selector.block_weights == nothing

        selector = RandomSelector(10, 2, wv)
        @test selector.holdout_blocks == 10
        @test selector.block_size == 1
        @test selector.seed == 2
        @test selector.block_weights == wv

        selector = RandomSelector(10, 2, 1)
        @test selector.holdout_blocks == 10
        @test selector.block_size == 2
        @test selector.seed == 1
        @test selector.block_weights == nothing

        selector = RandomSelector(10, 2, 1, wv)
        @test selector.holdout_blocks == 10
        @test selector.block_size == 2
        @test selector.seed == 1
        @test selector.block_weights == wv

        RandomSelector(10, 2) == RandomSelector(10, 1, 2)
    end

    @testset "basic" begin
        selector = RandomSelector(10, 1)
        @test selector isa DateSelector

        result = partition(date_range, selector)
        @test result isa NamedTuple{(:validation, :holdout)}
        @test sort(union(result...)) == date_range
        @test isempty(intersect(result...))

        # Running partition twice should return the same result
        result2 = partition(date_range, selector)
        @test collect(result.validation) == collect(result2.validation)
        @test collect(result.holdout) == collect(result2.holdout)

        # Setting num_holdout = all days leaves the validation set empty
        validation, holdout = partition(date_range, RandomSelector(length(date_range), 1))
        @test isempty(validation)
        @test collect(holdout) == date_range

        selector = RandomSelector(1, 3, 1)
        result = partition(date_range, selector)
        @test sort(union(result...)) == date_range
        @test isempty(intersect(result...))

        # Check 1 contiguous block of 3 days was selected
        holdout = collect(result.holdout)
        @test length(holdout) == 3
        @test holdout[2] == holdout[1] + Day(1)
        @test holdout[3] == holdout[1] + Day(2)
    end

    @testset "Set Seed" begin
        r1 = partition(date_range, RandomSelector(3, 1))
        r2 = partition(date_range, RandomSelector(3, 1))
        r3 = partition(date_range, RandomSelector(3, 1, nothing))

        # cannot directly equate NamedTuples of iterators
        @test collect(r1.validation) == collect(r2.validation) == collect(r3.validation)
        @test collect(r1.holdout) == collect(r2.holdout) == collect(r3.holdout)
        @test isequal(
            collect(r1.holdout),
            [Date(2019, 1, 4), Date(2019, 1, 10), Date(2019, 1, 15)]
        )

        r1 = partition(date_range, RandomSelector(3, 2, 1))
        r2 = partition(date_range, RandomSelector(3, 2, 1))
        r3 = partition(date_range, RandomSelector(3, 2, 1, nothing))

        # cannot directly equate NamedTuples of iterators
        @test collect(r1.validation) == collect(r2.validation) == collect(r3.validation)
        @test collect(r1.holdout) == collect(r2.holdout) == collect(r3.holdout)
        @test isequal(
            collect(r1.holdout),
            [
                Date(2019, 1, 7), Date(2019, 1, 8),
                Date(2019, 1, 19), Date(2019, 1, 20),
                Date(2019, 1, 29), Date(2019, 1, 30)
            ]
        )
    end

    @testset "Set Weights" begin
        wv = Weights([zeros(29); 1:3])

        result = partition(date_range, RandomSelector(3, 1, wv))
        @test isequal(
            collect(result.holdout),
            [Date(2019, 1, 30), Date(2019, 1, 31), Date(2019, 2, 1)]
        )

        wv = Weights([1:3; zeros(29)])
        result2 = partition(date_range, RandomSelector(3, 1, wv))
        @test isequal(
            collect(result2.holdout),
            [Date(2019, 1, 1), Date(2019, 1, 2), Date(2019, 1, 3)]
        )

        # length(date_range) / block_size = 16
        wv = Weights([zeros(13); 1:3])

        result = partition(date_range, RandomSelector(3, 2, 1, wv))
        @test isequal(
            collect(result.holdout),
            [
                Date(2019, 1, 27), Date(2019, 1, 28),
                Date(2019, 1, 29), Date(2019, 1, 30),
                Date(2019, 1, 31), Date(2019, 2, 1),
            ]
        )

        wv = Weights([1:3; zeros(13)])

        result = partition(date_range, RandomSelector(3, 2, 1, wv))
        @test isequal(
            collect(result.holdout),
            [
                Date(2019, 1, 1), Date(2019, 1, 2),
                Date(2019, 1, 3), Date(2019, 1, 4),
                Date(2019, 1, 5), Date(2019, 1, 6),
            ]
        )
    end

    @testset "error if selecting more days than available" begin
        @test_throws DomainError partition(date_range, RandomSelector(50, 1))

        # date_range will have 4 full weeks and 1 partial week
        @test_nowarn partition(date_range, RandomSelector(5, 7, 1))
        @test_throws DomainError partition(date_range, RandomSelector(6, 7, 1))
    end

    @testset "Different date inputs" begin
        exp = partition(date_range, RandomSelector(3, 1))

        @testset "$(typeof(d))" for d in (
            # Interval
            st..ed,
            # AnchoredInterval should include both start and dates
            AnchoredInterval{Day(31), Date}(st, true, true)
        )
            result = partition(d, RandomSelector(3, 1))
            @test collect(result.validation) == collect(exp.validation)
            @test collect(result.holdout) == collect(exp.holdout)
        end
    end
end
