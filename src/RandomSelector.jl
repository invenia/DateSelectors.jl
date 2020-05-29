
"""
    RandomSelector(
        holdout_blocks::Integer,
        block_size::Integer,
        seed::Integer,
        block_weights::Union{AbstractWeights, Nothing}=nothing,
    )

Determine holdout set by randomly subsampling `holdout_blocks` contiguous blocks of size `block_size` of holdout dates without
replacement using the `GLOBAL_RNG` seeded with `seed`.

The holdout dates will be sampled proportionally to the `block_weights` when they are provided.
"""
struct RandomSelector <: DateSelector
    holdout_blocks::Integer
    block_size::Integer
    seed::Integer
    block_weights::Union{AbstractWeights, Nothing}

    function RandomSelector(holdout_blocks, block_size, seed, block_weights::Union{AbstractWeights, Nothing}=nothing)
        return new(holdout_blocks, block_size, seed, block_weights)
    end
end

function RandomSelector(holdout_blocks, seed, block_weights::Union{AbstractWeights, Nothing}=nothing)
    return RandomSelector(holdout_blocks, 1, seed, block_weights)
end

function Iterators.partition(dates::StepRange{Date, Day}, s::RandomSelector)
    # Split the total days into contiguous blocks
    date_blocks = Iterators.partition(dates, s.block_size)

    if s.holdout_blocks > length(date_blocks)
        throw(DomainError(
            s.holdout_blocks,
            "Number of holdout blocks $(s.holdout_blocks) exceeds total number of date-blocks $(length(date_blocks))."
        ))
    end

    holdout_days = _subsample(
        Random.seed!(s.seed),
        collect(date_blocks), # _subsample doesn't work on iterators
        s.block_weights,
        s.holdout_blocks;
        replace=false
    )

    # Recombine dates to ensure return-type matches other DateSelectors
    return _getdatesets(dates, vcat(holdout_days...))
end

_subsample(rng, dates, ::Nothing, n; kwargs...) = sample(rng, dates, n; kwargs...)
_subsample(rng, dates, weights, n; kwargs...) = sample(rng, dates, weights, n; kwargs...)
