@testset "RandomSelector" begin
    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)
    date_range = st:Day(1):ed

    @testset "construction" begin
        selector = RandomSelector(2, 1//3)
        @test selector.seed == 2
        @test selector.holdout_fraction == 1//3
        @test selector.block_size == Day(1)
        @test selector.offset == Day(0)

        selector = RandomSelector(2, 1//3, Day(15))
        @test selector.seed == 2
        @test selector.holdout_fraction == 1//3
        @test selector.block_size == Day(15)
        @test selector.offset == Day(0)

        selector = RandomSelector(2, 1//3, Day(15), Day(5))
        @test selector.seed == 2
        @test selector.holdout_fraction == 1//3
        @test selector.block_size == Day(15)
        @test selector.offset == Day(5)


        @test (
            RandomSelector(99, 1//2, Day(1), Day(0)) ==
            RandomSelector(99, 1//2, Day(1)) ==
            RandomSelector(99, 1//2) ==
            RandomSelector(99)
        )
    end

    @testset "basic" begin
        selector = RandomSelector(42)
        @test selector isa DateSelector

        result = partition(date_range, selector)
        @test result isa NamedTuple{(:validation, :holdout)}
        @test sort(union(result...)) == date_range
        @test isempty(intersect(result...))

        # Running partition twice should return the same result
        result2 = partition(date_range, selector)
        @test result.validation == result2.validation
        @test result.holdout == result2.holdout

        @testset "holdout fraction" begin
            # Setting holdout_fraction 1 all days leaves the validation set empty
            validation, holdout = partition(date_range, RandomSelector(42, 1))
            @test isempty(validation)
            @test collect(holdout) == date_range

            # Setting holdout_fraction 0 all days leaves the holdout set empty
            validation, holdout = partition(date_range, RandomSelector(42, 0))
            @test isempty(holdout)
            @test collect(validation) == date_range
        end

        @testset "block size" begin
            selector = RandomSelector(42, 1//2, Day(3))
            result = partition(date_range, selector)
            @test sort(union(result...)) == date_range
            @test isempty(intersect(result...))


            for subset in result
                # at vary least the first 3 items must be from same block
                @test subset[2] == subset[1] + Day(1)
                @test subset[3] == subset[1] + Day(2)

                # no gaps of 2 are possible
                @test !any(isequal(2), diff(subset))
            end
        end
    end

    @testset "Right holdout fraction RandomSelector($seed, $holdout_fraction, $block_size)" for
        seed in (1, 42),
        holdout_fraction in (1//2, 0.1, 0.9, 0.7),
        block_size in (Day(1), Day(2), Week(1), Week(2))


        selector = RandomSelector(seed, holdout_fraction, block_size)
        range = Date(2000, 1, 1):Day(1):Date(2010, 1, 31)  # 10 year total range

        r = partition(range, selector)
        @test length(r.holdout)/length(range) ≈ holdout_fraction atol=0.05
    end

    @testset "Set Seed (protects against julia RNG changing)" begin
        r1 = partition(date_range, RandomSelector(42, 1//5))
        r2 = partition(date_range, RandomSelector(42, 1//5))
        r3 = partition(date_range, RandomSelector(42, 1//5))

        # cannot directly equate NamedTuples of iterators
        @test collect(r1.validation) == collect(r2.validation) == collect(r3.validation)
        @test collect(r1.holdout) == collect(r2.holdout) == collect(r3.holdout)
        @test isequal(r1.holdout, [Date(2019, 1, 1), Date(2019, 1, 5), Date(2019, 1, 30)])
    end

    @testset "Different date inputs" begin
        exp = partition(date_range, RandomSelector(42))

        @testset "$(typeof(d))" for d in (
            # Interval
            st..ed,
            # AnchoredInterval should include both start and dates
            AnchoredInterval{Day(31), Date, Closed, Closed}(st)
        )
            result = partition(d, RandomSelector(42))
            @test result.validation == exp.validation
            @test result.holdout == exp.holdout
        end
    end


    @testset "Invarient to date_range RandomSelector($seed, $holdout_fraction, $block_size, $offset))" for
        seed in (1, 42),
        holdout_fraction in (1//2, 1/20),
        block_size in (Day(1), Day(2), Week(1), Week(2)),
        offset in Day.(-3:3)


        selector = RandomSelector(seed, holdout_fraction, block_size, offset)  #only varient to the selector
        initial_range = Date(2019, 1, 1):Day(1):Date(2020, 1, 31)  # 1 year total range

        initial_sets = map(Set, partition(initial_range, selector))

        later_range = initial_range + Day(20)  # 20 days later.
        later_sets = map(Set, partition(later_range, selector))

        @test initial_sets.holdout ∩ later_sets.validation == Set()
        @test initial_sets.validation ∩ later_sets.holdout == Set()
    end
end
