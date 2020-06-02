
"""
    RandomSelector(
        holdout_fraction::Real,
        block_size::Period,
        seed::Integer,
        offset::Period=Day(0)
    )

Determine holdout set by randomly subsampling `holdout_blocks` contiguous blocks of size
`block_size` of holdout dates without replacement using the `GLOBAL_RNG` seeded with `seed`.
The probability of any given block being in the holdout set is given by `holdout_fraction`.

The `offset` is rarely needed, but is used to control block boundries.
It is given as a offset relative to _Monday 1st Jan 1900_.
For example, with the default offset of `Day(0)`, and if using a `Week(1)` `block_size`,
then every block will start on a Monday, and will go for 1 or more weeks from there.

Note that at the boundries of the partitioned dates the blocks may not be up to
`block_size` if they go over the edge -- this is infact the common case.
"""
struct RandomSelector <: DateSelector
    holdout_fraction::Real
    block_size::Period
    offset::Period
    seed::Integer
end

function Iterators.partition(dates::StepRange{Date, Day}, s::RandomSelector)
    if !(0 <= s.holdout_fraction <= 1)
        throw(DomainError(s.holdout_fraction, "holdout fraction must be between 0 and 1 (inclusive)"))
    end
    rng = MersenneTwister(s.seed)
    sd, ed = extrema(dates)

    initial_time = _determine_initial_time(s, dates)


    holdout_dates = Date[]
    curr_window = initial_time:step(dates):(initial_time + s.block_size - step(dates))
    while first(curr_window) <= ed
        # Important: we must generate a random number for every block even before the start
        # so that the `rng` state is updated constistently no matter when the start is
        # and thus `partition` is invarient on the start date
        r = rand(rng)

        # optimization: only creating holdout window if intersect not empty
        if last(curr_window) >= sd
            if r < s.holdout_fraction
                curr_active_window = curr_window ∩ dates  # handle being near boundries
                append!(holdout_dates, curr_active_window)
        end
        curr_window = curr_window .+ s.block_size
    end

    return _getdatesets(dates, holdout_dates)
end
