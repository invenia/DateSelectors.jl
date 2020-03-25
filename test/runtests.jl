using DateSelectors
using Dates
using Intervals
using Random
using StatsBase: Weights, sample
using Test

Random.seed!(1)

@testset "DateSelectors.jl" begin

    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)
    date_range = st:Day(1):ed

    @testset "_getdatesets" begin

        @testset "easy partition" begin

            holdout_dates = date_range[1:10]
            val_dates = date_range[11:end]

            result = DateSelectors._getdatesets(date_range, holdout_dates)

            @test result isa NamedTuple{(:validation, :holdout)}
            @test result.validation == first(result)
            @test result.holdout == last(result)

            @test result.validation isa Base.Generator
            @test result.holdout isa Base.Generator

            @test collect(result.holdout) == holdout_dates
            @test collect(result.validation) == val_dates
        end

        @testset "single date" begin
            date = sample(date_range)
            result = DateSelectors._getdatesets(date_range, date)

            @test collect(result.holdout) == [date]
            @test .!any(in(result.holdout), result.validation)
            @test sort(collect(union(result...))) == date_range
        end

        @testset "random partition" begin
            dates = sample(date_range, 10)
            result = DateSelectors._getdatesets(date_range, dates)

            @test collect(result.holdout) != dates
            @test collect(result.holdout) == sort(dates)
            @test .!any(in(result.holdout), result.validation)
            @test sort(collect(union(result...))) == date_range
        end
    end

    @testset "NoneSelector" begin
        selector = NoneSelector()
        @test selector isa DateSelector

        validation, holdout = partition(date_range, selector)
        @test collect(validation) == date_range
        @test isempty(holdout)
    end

    @testset "PeriodicSelector" begin

        @testset "1 week period, 1 day stride" begin

            selector = PeriodicSelector(Week(1))
            @test selector isa DateSelector

            result = partition(date_range, selector)
            @test sort(vcat(collect.(vcat(result...))...)) == date_range
            @test isempty(intersect(result...))

            expected_holdout = [st:Week(1):ed...]
            @test collect(result.holdout) == expected_holdout
        end

        @testset "2 week period, 5 day stride" begin

            selector = PeriodicSelector(Week(2), Day(5))
            result = partition(date_range, selector)
            @test sort(vcat(collect.(vcat(result...))...)) == date_range
            @test isempty(intersect(result...))

            expected_holdout = [
                st:Day(1):st + Day(4)...,
                st + Week(2):Day(1):st + Week(2) + Day(4)...,
                st + Week(4):Day(1):st + Week(4) + Day(3)...,
            ]
            @test collect(result.holdout) == expected_holdout
        end

        @testset "1 week period, 1 day stride, 1 day offset" begin

            selector = PeriodicSelector(Week(1), Day(1), Day(1))

            result = partition(date_range, selector)
            @test sort(vcat(collect.(vcat(result...))...)) == date_range
            @test isempty(intersect(result...))

            expected_holdout = [st+Day(1):Week(1):ed...]
            @test collect(result.holdout) == expected_holdout
        end

        @testset "BiWeekly" begin
            selector = PeriodicSelector(Week(2), Week(1))

            result = partition(date_range, selector)
            @test isempty(intersect(result...))

            expected_holdout = [
                st:Day(1):st+Day(6)...,
                st+Week(2):Day(1):st+Week(3)-Day(1)...,
                st+Week(4):Day(1):ed...,
            ]

            expected_validation = [
                st+Week(1):Day(1):st+Week(2)-Day(1)...,
                st+Week(3):Day(1):st+Week(4)-Day(1)...,
            ]

            @test collect(result.holdout) == expected_holdout
            @test collect(result.validation) == expected_validation
        end

        @testset "Weekends as holdout" begin

            selector = PeriodicSelector(Week(1), Day(2), Day(4))
            validation, holdout = partition(date_range, selector)

            @test sort(unique(dayname.(validation))) == ["Friday", "Monday", "Thursday", "Tuesday", "Wednesday"]
            @test sort(unique(dayname.(holdout))) == ["Saturday", "Sunday"]

        end

        @testset "stride, offset, period wrong domain" begin
            @test_throws DomainError PeriodicSelector(Day(0))
            @test_throws DomainError PeriodicSelector(Day(7), Day(0))
            @test_throws DomainError PeriodicSelector(Day(7), Day(3), Day(-1))

            @test_throws DomainError PeriodicSelector(Hour(24))
            @test_throws DomainError PeriodicSelector(Day(7), Hour(48))
            @test_throws DomainError PeriodicSelector(Day(7), Day(3), Hour(72))
        end

        @testset "errors if stride + offset > period" begin
            @test_throws ArgumentError PeriodicSelector(Day(2), Day(3))
            @test_throws ArgumentError PeriodicSelector(Week(1), Day(4), Day(4))
        end
    end

    @testset "RandomSelector" begin

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

    @testset "Sanity checks on partitioning" begin
        st = Date(2018, 1, 1)
        ed = Date(2019, 1, 1)

        datesets = (
            st:Day(1):ed,
            st:Day(2):ed,
            st..ed,
            AnchoredInterval{Day(365), Date}(st),
        )

        selectors = (
            NoneSelector(),
            PeriodicSelector(Week(2), Week(1)),
            RandomSelector(4, 10, 1),
        )

        @testset "$(repr(selector))" for selector in selectors, dateset in datesets
            a, b = partition(dateset, selector)
            @test all(in(dateset), a)
            @test all(in(dateset), b)
            @test isempty(intersect(a, b))

            if dateset isa AbstractInterval
                 _dateset = DateSelectors._interval2daterange(dateset)
                 @test sort(union(a, b)) == collect(_dateset)
            else
                @test sort(union(a, b)) == collect(dateset)
            end

        end
    end

    @testset "Vector of days is not allowed" begin
        @test_throws MethodError partition(collect(date_range), NoneSelector())
    end

    @testset "Weekly intervals are not allowed" begin
        weekly_dates = st:Week(1):ed

        for selector in (
            NoneSelector(),
            PeriodicSelector(Week(2), Week(1)),
            RandomSelector(1, 2, 1),
        )
            @test_throws MethodError partition(weekly_dates, selector)
        end
    end

    include("deprecated.jl")

end
