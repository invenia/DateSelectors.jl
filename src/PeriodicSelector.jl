
"""
    PeriodicSelector(period::Period, stride::Period=Day(1), offset::Period=Day(0))

Assign holdout dates by taking a set of size `stride` once per `period` starting from the
start date + `offset`.

For example, `PeriodicSampler(Week(1), Day(2), Day(1))` will select 2 days per week with an
offset of 1 day resulting in the holdout dates corresponding to the second and third days of
each week from the start date.
"""
struct PeriodicSelector <: DateSelector
    period::Period
    stride::Period
    offset::Period

    function PeriodicSelector(period::Period, stride::Period=Day(1), offset::Period=Day(0))

        period ≥ Day(2) || throw(DomainError(period, "period must be at least 2 Days."))
        stride ≥ Day(1) || throw(DomainError(stride, "stride must be at least 1 Day."))
        offset ≥ Day(0) || throw(DomainError(offset, "offset cannot be negative."))

        if any(isa.([period, stride, offset], Ref(Hour)))
            throw(DomainError("period, stride, and offset cannot be expressed in Hours."))
        end

        if Day(stride) + Day(offset) > Day(period)
            throw(ArgumentError(
                "Cannot take a $stride stride with offset $offset within a $period period."
            ))
        end

        return new(period, stride, offset)
    end
end


function Iterators.partition(dates::StepRange{Date, Day}, s::PeriodicSelector)
    sd, ed = extrema(dates)

    holdout_dates = Date[]
    curr = sd
    curr += s.offset
    while curr + s.stride <= ed
        #TODO: in future we want to remove the assumption of a 1 day interval
        stop = curr + s.stride - step(dates)
        push!(holdout_dates, curr:step(dates):stop...)
        curr += s.period
    end

    push!(holdout_dates, curr:step(dates):ed...)

    return _getdatesets(dates, holdout_dates)
end
