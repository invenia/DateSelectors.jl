
"""
    PeriodicSelector(period::Period, stride::Period=Day(1), offset::Period=Day(0))

Assign holdout dates by taking a set of size `stride` once per `period`.
The offset is relative to _Sunday 1st Jan 1899, and controls when the selected section starts.

For example, `PeriodicSampler(Week(1), Day(2), Day(1))` will select 2 days per week.
With this selected periods offset by 1 day from 1st Jan 1899.
I.e. if applied to the first two weeks of the year 1899,
it would select 2nd, 3rd, 9th and 8th of Jan 1899
"""
struct PeriodicSelector <: DateSelector
    period::Period
    stride::Period
    offset::Period

    function PeriodicSelector(period::Period, stride::Period=Day(1), offset::Period=Day(0))
        period ≥ Day(2) || throw(DomainError(period, "period must be at least 2 Days."))
        stride ≥ Day(1) || throw(DomainError(stride, "stride must be at least 1 Day."))

        if any(isa.([period, stride, offset], Ref(Hour)))
            throw(DomainError("period, stride, and offset cannot be expressed in Hours."))
        end

        if Day(stride) > Day(period)
            throw(ArgumentError(
                "Cannot take a $stride stride within a $period period."
            ))
        end

        return new(period, stride, offset)
    end
end


function Iterators.partition(dates::StepRange{Date, Day}, s::PeriodicSelector)
    sd, ed = extrema(dates)

    # The order from FERC that created the US ISO's (the first of their kind) came in 1999
    # thus seems safe to start in 1899, which has the convient feature of
    # starting on a Sunday
    beginning_of_time = Date(1899)
    initial_time = beginning_of_time + s.offset + Day(1)
    sd < initial_time && throw(DomainError(
        sd,
        "PeriodicSelector with offset $(s.offset) cannot be used before $(initial_time)",
    ))

    #NOTE: you might be thinking that this process that actually checks all dates starting
    # from year 1899 is too slow and we should do something smart with modulo arithmetic
    # but for current decades this takes thousands of a second and even for year 9000
    # is still is well under 1/4 second. so keeping it simple

    holdout_dates = Date[]
    #TODO: in future we want to remove the assumption of a 1 day interval
    curr_window = initial_time:step(dates):(initial_time + s.stride - step(dates))
    while first(curr_window) <= ed
        # optimization: only creating holdout window if intersect not empty
        if last(curr_window) >= sd
            curr_holdout_window = curr_window ∩ dates
            append!(holdout_dates, curr_holdout_window)
        end
        curr_window = curr_window .+ s.period
    end

    return _getdatesets(dates, holdout_dates)
end
