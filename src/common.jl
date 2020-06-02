
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

"""
    _determine_initial_time(s::S, dates) where S<: DateSelector

Determines when we start counting from when breaking `dates` up into blocks.
Checks that that initial time is valid for the given `dates`.
"""
function _determine_initial_time(s::S, dates) where S<: DateSelector
    sd, ed = extrema(dates)

    # The order from FERC that created the US ISO's (the first of their kind) came in 1999
    # thus seems safe to start in 1900, which has the convient feature of
    # starting on a Monday
    beginning_of_time = Date(1900)
    initial_time = beginning_of_time + s.offset
    sd < initial_time && throw(DomainError(
        sd,
        "$S with offset $(s.offset) cannot be used before $(initial_time)",
    ))
    return initial_time
end
