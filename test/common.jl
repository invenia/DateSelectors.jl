@testset "_getdatesets" begin
    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)
    date_range = st:Day(1):ed

    @testset "easy partition" begin

        holdout_dates = date_range[1:10]
        val_dates = date_range[11:end]

        result = DateSelectors._getdatesets(date_range, holdout_dates)

        @test result isa NamedTuple{(:validation, :holdout)}
        @test result.validation == first(result)
        @test result.holdout == last(result)

        @test Base.isiterable(typeof(result.validation))
        @test Base.isiterable(typeof(result.holdout))

        @test result.holdout == holdout_dates
        @test result.validation == val_dates
    end

    @testset "single date" begin
        date = rand(date_range)
        result = DateSelectors._getdatesets(date_range, date)

        @test result.holdout == [date]
        @test isempty(intersect(result...))
        @test sort(union(result...)) == date_range
    end

    @testset "random partition" begin
        dates = unique(rand(date_range, 10))
        result = DateSelectors._getdatesets(date_range, dates)

        @test result.holdout != dates
        @test result.holdout == sort(dates)
        @test isempty(intersect(result...))
        @test sort(union(result...)) == date_range
    end

    @testset "parsing" begin
        # Just the type
        @test_throws ArgumentError parse(DateSelector, "NoneSelector")
        # Misspelling
        @test_throws ArgumentError parse(DateSelector, "NonSelector()")
        # Wrong expression
        @test_throws ArgumentError parse(DateSelector, "NoneSelector() isa NoneSelector")
        # Extra stuff in the string
        @test_throws Base.Meta.ParseError parse(DateSelector, "NoneSelector() 1")

        # Wrong args
        @test_throws MethodError parse(DateSelector, "PeriodicSelector()")
        @test_throws MethodError parse(DateSelector, "PeriodicSelector(14)")

        # Spacing
        @test parse(DateSelector, "   NoneSelector(  ) ") isa NoneSelector

        s = parse(DateSelector, "NoneSelector()")
        @test s == NoneSelector()
        # Check specific type works
        s = parse(NoneSelector, "NoneSelector()")
        @test s == NoneSelector()

        s = parse(DateSelector, "PeriodicSelector(Day(2))")
        @test s == PeriodicSelector(Day(2))
        s = parse(DateSelector, "PeriodicSelector(Day(6), Day(4), Day(1))")
        @test s == PeriodicSelector(Day(6), Day(4), Day(1))
        # Check specific type works
        s = parse(PeriodicSelector, "PeriodicSelector(Day(2))")
        @test s == PeriodicSelector(Day(2))

        s = parse(DateSelector, "RandomSelector(1)")
        @test s == RandomSelector(1, 1//2, Day(1), Day(0))
        s = parse(DateSelector, "RandomSelector(123, 1//4, Day(7),  Day(1))")
        @test s == RandomSelector(123, 1//4, Day(7), Day(1))
        # Check specific type works
        s = parse(RandomSelector, "RandomSelector(1)")
        @test s == RandomSelector(1, 1//2, Day(1), Day(0))

        s = PeriodicSelector(Day(2))
        @test s == parse(DateSelector, string(s))
    end

    @testset "show" begin
        if VERSION < v"1.5"
            # Check we have undone the period printing for DateSelectors alone
            @test repr(PeriodicSelector(Day(6), Day(4), Day(1))) != "PeriodicSelector(6 days, 4 days, 1 day)"
            @test repr((Day(6), Day(4), Day(1))) == "(6 days, 4 days, 1 day)"
        end

        @test repr(PeriodicSelector(Day(2))) == "PeriodicSelector(Day(2), Day(1), Day(0))"
        @test repr(RandomSelector(1)) == "RandomSelector(1, 1//2, Day(1), Day(0))"
        @test repr(NoneSelector()) == "NoneSelector()"
    end
end
