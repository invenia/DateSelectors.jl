
"""
    PeriodicSelector(period::DatePeriod, stride::DatePeriod=Day(1), offset::DatePeriod=Day(0))

Assign holdout dates by taking a set of size `stride` once per `period`.
The offset is relative to _Monday 1st Jan 1900_, and controls when the selected section starts.

For example, `PeriodicSelector(Week(1), Day(2), Day(1))` will select 2 days per week.
With this selected periods offset by 1 day from 1st Jan 1900.
I.e. if applied to the first two weeks of the year 1900,
it would select 2nd, 3rd, 9th and 8th of Jan 1900.

Note: this cannot be actually used to select days earlier than `offset` after
1st Jan 1900.
"""
struct PeriodicSelector <: DateSelector
    period::DatePeriod
    stride::DatePeriod
    offset::DatePeriod

    function PeriodicSelector(period, stride=Day(1), offset=Day(0))
        period ≥ Day(2) || throw(DomainError(period, "period must be at least 2 Days."))
        stride ≥ Day(1) || throw(DomainError(stride, "stride must be at least 1 Day."))

        if Day(stride) > Day(period)
            throw(ArgumentError(
                "Cannot take a $stride stride within a $period period."
            ))
        end

        return new(period, stride, offset)
    end
end


function Iterators.partition(dates::StepRange{Date, Day}, s::PeriodicSelector)
    initial_time = _determine_initial_time(s, dates)
    sd, ed = extrema(dates)

    #NOTE: you might be thinking that this process that actually checks all dates starting
    # from year 1900 is too slow and we should do something smart with modulo arithmetic
    # but for current decades this takes thousands of a second and even for year 9000
    # is still is well under 1/4 second. so keeping it simple

    holdout_dates = Date[]
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
