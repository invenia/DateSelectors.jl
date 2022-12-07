"""
    NoneSelector()

Assign all dates to the validation set, select no holdout dates.
"""
struct NoneSelector <: DateSelector end

function Iterators.partition(dates::AbstractVector{Date}, ::NoneSelector)
    # Just to maintain consistency between selectors
    if dates isa StepRange && step(dates) != Day(1)
        throw(ArgumentError("Expected step range over days, not ($(step(dates)))."))
    end

    return _getdatesets(dates, Date[])
end
