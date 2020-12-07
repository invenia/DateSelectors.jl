@testset "NoneSelector" begin
    st = Date(2019, 1, 1)
    ed = Date(2019, 2, 1)
    date_range = st:Day(1):ed

    selector = NoneSelector()
    @test selector isa DateSelector

    validation, holdout = partition(date_range, selector)
    @test validation == date_range
    @test isempty(holdout)
end
