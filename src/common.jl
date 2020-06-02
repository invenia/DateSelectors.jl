
"""
    DateSelector

Determines how to [`partition`](@ref) a date set into disjoint validation and holdout sets.
"""
abstract type DateSelector end


"""
    partition(dates::AbstractInterval{Date}, s::DateSelector)
    partition(dates::StepRange{Date, Day}, selector::DateSelector)

Partition the set of `dates` into disjoint `validation` and `holdout` sets according to the
`selector` and return a `NamedTuple({:validation, :holdout})` of iterators.
"""
function Iterators.partition(dates::AbstractInterval{Date}, s::DateSelector)
    _dates = _interval2daterange(dates)
    return partition(_dates, s)
end


"""
    _getdatesets(st, ed, dates) -> NamedTuple{(:validation, :holdout)}

Construct the NamedTuple of iterators for the validation and holdout date sets.
"""
function _getdatesets(all_dates, holdout_dates)
    return (
        validation=(vd for vd in sort(setdiff(all_dates, holdout_dates))),
        holdout=(hd for hd in sort(holdout_dates))
    )
end

_getdatesets(all_dates, date::Date) = _getdatesets(all_dates, [date])

"""
    _interval2daterange(dates::AbstractInterval{Day}) -> StepRange{Date, Day}

Helper function to turn an AbstractInterval into a StepRange taking the inclusivity into
account.
"""
function _interval2daterange(dates::AbstractInterval{Date})
    fd = first(inclusivity(dates)) ? first(dates) : first(dates) + Day(1)
    ld = last(inclusivity(dates)) ? last(dates) : last(dates) - Day(1)
    return fd:Day(1):ld
end
