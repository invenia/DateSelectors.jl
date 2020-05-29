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
