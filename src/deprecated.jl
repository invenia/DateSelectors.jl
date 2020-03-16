using Base: @deprecate

@deprecate(
    RandomSelector(
        num_holdout,
        weights::Union{AbstractWeights, Nothing},
        rng::AbstractRNG
    ),
    RandomSelector(num_holdout, 1, weights)
)

@deprecate(
    RandomSelector(
        num_holdout,
        seed::Integer,
        weights::Union{AbstractWeights, Nothing},
        rng::AbstractRNG
    ),
    RandomSelector(num_holdout, seed, weights)
)
