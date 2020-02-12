module DateSelectors

using Dates
using Random
using StatsBase: sample, AbstractWeights

export DateSelector, NoneSelector, PeriodicSelector, RandomSelector, partition

"""
    DateSelector

Used in [`partition`](@ref) to select a set of holdout dates using some criteria.
"""
abstract type DateSelector end

"""
    _getdatesets(st, ed, dates)

Returns the holdout dates and their complement as a NamedTuple
"""
_getdatesets(st, ed, dates) = (holdout=dates, validation=setdiff(st:Day(1):ed, dates))

"""
    partition(selector::DateSelector, start_date::Date, end_date::Date) -> NamedTuple{(:holdout, :validation), Tuple{Vector{Date}, Vector{Date}}}
    partition(selector::DateSelector, date_range::StepRange{Date, Day}) -> NamedTuple{(:holdout, :validation), Tuple{Vector{Date}, Vector{Date}}}

Partition the dates between `start_date` and `end_date` into disjoint `holdout` and `validation` sets according to the `selector`.
Returns a NamedTuple of the selected `holdout` dates and the complementary set of `validation` dates.
"""
partition(s::DateSelector, dates::StepRange{Date, Day}) = partition(s, first(dates), last(dates))

"""
    PeriodicSelector(period::Period, stride::Period=Day(1), offset::Period=Day(0))

Selects holdout dates uniformly by taking a set of size `stride` once per `period` starting from the start date + `offset`.
For example `PeriodicSampler(Week(1), Day(2), Day(1))` takes 2 days per week with an offset of 1 day.
This results in the holdout dates being the second and third days of each week where each week is counted from the start date given to [`partition`](@ref).
"""
struct PeriodicSelector <: DateSelector
    period::Period
    stride::Period
    offset::Period

    PeriodicSelector(period::Period, stride::Period=Day(1), offset::Period=Day(0)) = new(period, stride, offset)
end

function partition(s::PeriodicSelector, sd::Date, ed::Date)
    dates = Date[]
    curr = sd
    curr += s.offset
    while curr + s.stride <= ed
        push!(dates, curr:Day(1):curr+s.stride-Day(1)...)
        curr += s.period
    end

    return _getdatesets(sd, ed, dates)
end

"""
    RandomSelector(num_holdout::Integer, seed::Integer, weights::Union{AbstractWeights, Nothing}=nothing, rng::AbstractRNG=Random.GLOBAL_RNG)
    RandomSelector(num_holdout::Integer, weights::AbstractWeights, Nothing}=nothing, rng::AbstractRNG=Random.GLOBAL_RNG)

Randomly subsamples `num_holdout` holdout dates without replacement using `rng` seeded with `seed`.
The holdout dates will be sampled proportionally to `weights` when `weights` is not `nothing`.
"""
struct RandomSelector <: DateSelector
    num_holdout::Integer
    weights::Union{AbstractWeights, Nothing}
    rng::AbstractRNG

    RandomSelector(num_holdout::Integer, weights=nothing, rng::AbstractRNG=Random.GLOBAL_RNG) = new(num_holdout, weights, rng)
end

function RandomSelector(num_holdout::Integer, seed::Integer, weights::Union{AbstractWeights, Nothing}=nothing, rng::AbstractRNG=Random.GLOBAL_RNG)
    RandomSelector(num_holdout, weights, Random.seed!(rng, seed))
end

function partition(s::RandomSelector, sd::Date, ed::Date)
    dates = collect(sd:Day(1):ed)
    holdout_days = _subsample(s.rng, dates, s.weights, s.num_holdout)

    _getdatesets(sd, ed, holdout_days)
end

_subsample(rng, dates, ::Nothing, num) = sample(rng, dates, num; replace=false)
_subsample(rng, dates, weights, num) = sample(rng, dates, weights, num; replace=false)

"""
    NoneSelector()

Selects no holdout dates.
"""
struct NoneSelector <: DateSelector end

partition(::NoneSelector, sd::Date, ed::Date) = _getdatesets(sd, ed, Date[])

end # module
