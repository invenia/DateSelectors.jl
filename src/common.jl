
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
        validation=sort(setdiff(all_dates, holdout_dates)),
        holdout=sort(holdout_dates)
    )
end

_getdatesets(all_dates, date::Date) = _getdatesets(all_dates, [date])

"""
    _interval2daterange(dates::AbstractInterval{Day}) -> StepRange{Date, Day}

Helper function to turn an AbstractInterval into a StepRange taking the inclusivity into
account.
"""
function _interval2daterange(dates::AbstractInterval{Date})
    fd = minimum(dates, increment=Day(1))
    ld = maximum(dates, increment=Day(1))
    return fd:Day(1):ld
end

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
