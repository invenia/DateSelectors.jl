@testset "Sensibility checks" begin
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
        date_range = collect(Date(2019, 1, 1):Day(1):Date(2019, 2, 1))
        @test_throws MethodError partition(date_range, NoneSelector())
    end

    @testset "Weekly intervals are not allowed" begin
        st = Date(2019, 1, 1)
        ed = Date(2019, 2, 1)
        weekly_dates = st:Week(1):ed

        for selector in (
            NoneSelector(),
            PeriodicSelector(Week(2), Week(1)),
            RandomSelector(1, 2, 1),
        )
            @test_throws MethodError partition(weekly_dates, selector)
        end
    end
end
