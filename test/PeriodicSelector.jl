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
