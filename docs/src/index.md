# DateSelectors.jl

`DateSelectors.jl` simplifies the partitioning of a collection of dates into non-contiguous validation and holdout sets.

The package exports the `partition` function, which assigns dates to the validation and holdout sets according to the `DateSelector`.
The available `DateSelector`s are:
1. `NoneSelector`: assigns all dates to the validation set.
1. `RandomSelector`: randomly draws a subset of dates _without_ replacement.
1. `PeriodicSelector`: draws contiguous subsets of days periodically from the collection.
