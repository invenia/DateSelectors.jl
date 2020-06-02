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
        dates = rand(date_range, 10)
        result = DateSelectors._getdatesets(date_range, dates)

        @test result.holdout != dates
        @test result.holdout == sort(dates)
        @test isempty(intersect(result...))
        @test sort(union(result...)) == date_range
    end
end
