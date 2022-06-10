
"""
    DateSelector

Determines how to [`partition`](@ref) a date set into disjoint validation and holdout sets.
"""
abstract type DateSelector end


"""
    partition(dates::AbstractInterval{Date}, s::DateSelector; )
    partition(dates::StepRange{Date, Day}, selector::DateSelector)

Partition the set of `dates` into disjoint `validation` and `holdout` sets according to the
`selector` and return a `NamedTuple({:validation, :holdout})` of iterators.
"""
function Iterators.partition(dates::AbstractInterval{Date}, s::DateSelector)
    _dates = _interval2daterange(dates)
    return partition(_dates, s)
end


"""
    _getdatesets(st, ed, dates; bad_dates=[]) -> NamedTuple{(:validation, :holdout)}

Construct the NamedTuple of iterators for the validation and holdout date sets.
Optionally excludes dates in bad_dates.
"""
function _getdatesets(all_dates, holdout_dates; bad_dates=[])

    all_dates = filter(!in(bad_dates), all_dates)
    holdout_dates = filter(!in(bad_dates), holdout_dates)

    return (
        validation=sort(setdiff(all_dates, holdout_dates)),
        holdout=sort(holdout_dates)
    )
end

_getdatesets(all_dates, date::Date; bad_dates=[]) = _getdatesets(all_dates, [date];bad_dates=bad_dates)

"""
    _interval2daterange(dates::AbstractInterval{Day}) -> StepRange{Date, Day}

Helper function to turn an AbstractInterval into a StepRange taking the inclusivity into
account.
"""
function _interval2daterange(dates::AbstractInterval{Date})
    fd = _firstdate(dates)
    ld =_lastdate(dates)
    return fd:Day(1):ld
end

# TODO: remove this once https://github.com/invenia/Intervals.jl/issues/137
# is addressed.
_firstdate(dates::AbstractInterval{Date,Closed}) = first(dates)
_firstdate(dates::AbstractInterval{Date,Open}) = first(dates) + Day(1)
_lastdate(dates::AbstractInterval{Date,<:Bound,Closed}) = last(dates)
_lastdate(dates::AbstractInterval{Date,<:Bound,Open}) = last(dates) - Day(1)

"""
    _initial_date(s::S, dates) where S<: DateSelector

Determines when we start counting from when breaking `dates` up into blocks.
Checks that that initial time is valid for the given `dates`.
"""
function _initial_date(s::S, dates) where S<: DateSelector
    sd, ed = extrema(dates)

    # We would like to start from over 100 years ago
    # 1900, which has the convient feature of starting on a Monday
    beginning_of_time = Date(1900)
    initial_time = beginning_of_time + s.offset
    sd < initial_time && throw(DomainError(
        sd,
        "$S with offset $(s.offset) cannot be used before $(initial_time)",
    ))
    return initial_time
end

function Base.parse(DT::Type{<:DateSelector}, s::AbstractString)
    expr = Meta.parse(s)

    if expr isa Expr && expr.head == :call && isdefined(@__MODULE__, expr.args[1])
        T = getfield(@__MODULE__, expr.args[1])
        T isa Type && T <: DT && return eval(expr)
    end

    throw(ArgumentError("Could not parse \"$s\" as a `$DT`"))
end

if VERSION < v"1.5"
    function Base.show(io::IO, s::S) where S<:DateSelector
        args = _stringarg.(getfield.(Ref(s), fieldnames(S)))

        print(io, "$S($(join(args, ", ")))")
    end

    # Periods print in a format that breaks our parsing
    # So we undo their formatting
    _stringarg(p::Period) = "$(typeof(p))($(p.value))"
    _stringarg(arg) = repr(arg)
end
