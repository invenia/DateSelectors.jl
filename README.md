# DateSelectors
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/DateSelectors.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/DateSelectors.jl/dev)
[![CI](https://github.com/Invenia/DateSelectors.jl/workflows/CI/badge.svg)](https://github.com/Invenia/DateSelectors.jl/actions?query=workflow%3ACI)
[![code style blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

# Usage

`DateSelectors.jl` simplifies the partitioning of a collection of dates into non-contiguous validation and holdout sets in line with best practices for tuning hyper-parameters, for time-series machine learning.

The package exports the `partition` function, which assigns dates to the validation and holdout sets according to the `DateSelector`.
The available `DateSelector`s are:
1. `NoneSelector`: assigns all dates to the validation set.
1. `RandomSelector`: randomly draws a subset of dates _without_ replacement.
1. `PeriodicSelector`: draws contiguous subsets of days periodically from the collection.

A notable trait of the `DateSelector`s is that the selection is invariant to the start and end-dates of collection itself.
Thus you can shift the start and end dates, e.g. by a week, and the days in the overlapping period will consitently still be placed into holdout or validation as before.
The only thing that controls if a date is selected or not is the parameters of the `DateSelector` itself.

See the [examples](https://github.com/invenia/DateSelectors.jl/docs/src/examples.md) in the docs for more info.
