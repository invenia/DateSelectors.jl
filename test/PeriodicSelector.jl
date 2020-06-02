@testset "PeriodicSelector" begin
    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)
    date_range = st:Day(1):ed

    @testset "1 week period, 1 day stride" begin

        selector = PeriodicSelector(Week(1))
        @test selector isa DateSelector

        result = partition(date_range, selector)
        @test sort(vcat(collect.(vcat(result...))...)) == date_range
        @test isempty(intersect(result...))

        @test all(isequal(Week(1)), diff(collect(result.holdout)))
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
        @test diff(collect(result.holdout)) == Day.([1, 1, 1, 1, 10, 1, 1, 1, 1])
    end

    @testset "1 week period, 1 day stride, 2 day offset" begin
        selector = PeriodicSelector(Week(1), Day(1), Day(2))

        result = partition(date_range, selector)
        @test sort(vcat(collect.(vcat(result...))...)) == date_range
        @test isempty(intersect(result...))

        expected_holdout = [st+Day(1):Week(1):ed...]
        @test collect(result.holdout) == expected_holdout
    end

    @testset "BiWeekly" begin
        st1 = Date(1900, 1, 1)
        ed1 = Date(1900, 2, 1)
        date_range1 = st1:Day(1):ed1

        selector = PeriodicSelector(Week(2), Week(1))

        result = partition(date_range1, selector)
        @test isempty(intersect(result...))

        expected_holdout = [
            st1:Day(1):st1+Day(6)...,
            st1+Week(2):Day(1):st1+Week(3)-Day(1)...,
            st1+Week(4):Day(1):ed1...,
        ]

        expected_validation = [
            st1+Week(1):Day(1):st1+Week(2)-Day(1)...,
            st1+Week(3):Day(1):st1+Week(4)-Day(1)...,
        ]

        @test collect(result.holdout) == expected_holdout
        @test collect(result.validation) == expected_validation
    end

    @testset "Day of week" begin
        @testset "Weekends as holdout" begin
            selector = PeriodicSelector(Week(1), Day(2), Day(5))
            validation, holdout = partition(date_range, selector)

            @test isequal(
                sort(unique(dayname.(validation))),
                ["Friday", "Monday", "Thursday", "Tuesday", "Wednesday"]
            )
            @test sort(unique(dayname.(holdout))) == ["Saturday", "Sunday"]
        end

        @testset "Week days as holdout" begin
            selector = PeriodicSelector(Week(1), Day(5))
            validation, holdout = partition(date_range, selector)

            @test sort(unique(dayname.(validation))) == ["Saturday", "Sunday"]
            @test isequal(
                sort(unique(dayname.(holdout))),
                ["Friday", "Monday", "Thursday", "Tuesday", "Wednesday"]
            )
        end
    end

    @testset "stride, offset, period wrong domain" begin
        @test_throws DomainError PeriodicSelector(Day(0))
        @test_throws DomainError PeriodicSelector(Day(7), Day(0))

        @test_throws DomainError PeriodicSelector(Hour(24))
        @test_throws DomainError PeriodicSelector(Day(7), Hour(48))
        @test_throws DomainError PeriodicSelector(Day(7), Day(3), Hour(72))
    end

    @testset "errors if stride > period" begin
        @test_throws ArgumentError PeriodicSelector(Day(2), Day(3))
        @test_throws ArgumentError PeriodicSelector(Week(1), Day(8))
    end

    @testset "Invarient to date_range (period $period, stride $stride)" for
        (period, stride) in ((Week(2), Week(1)), (Day(30), Day(10)), (Day(5), Day(2)))

        @testset "offset $offset" for offset in Day.((0, 1, 2, 3))
            selector = PeriodicSelector(period, stride, offset)
            initial_range = Date(2029, 1, 1):Day(1):Date(2030, 1, 31)
            initial_sets = map(Set, partition(initial_range, selector))

            later_range = initial_range + Day(20)  # 20 days later.
            later_sets = map(Set, partition(later_range, selector))

            @test initial_sets.holdout ∩ later_sets.validation == Set()
            @test initial_sets.validation ∩ later_sets.holdout == Set()
        end
    end
end
