# DateSelectors

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.pages.invenia.ca/research/DateSelectors.jl/)
[![Build Status](https://gitlab.invenia.ca/invenia/research/DateSelectors.jl/badges/master/build.svg)](https://gitlab.invenia.ca/invenia/research/DateSelectors.jl/commits/master)
[![Coverage](https://gitlab.invenia.ca/invenia/research/DateSelectors.jl/badges/master/coverage.svg)](https://gitlab.invenia.ca/invenia/research/DateSelectors.jl/commits/master)

# Usage

`DateSelectors.jl` simplifies the partitioning of a collection of dates into non-contiguous validation and holdout sets in line with [our best practices](TODO add link) for [tuning hyper-parameters](https://gitlab.invenia.ca/invenia/research/sagemakersubmit) in [EIS](https://gitlab.invenia.ca/invenia/eis).

The package exports the `partition` function, which assigns dates to the validation and holdout sets according to the `DateSelector`.
The available `DateSelector`s are:
1. `NoneSelector`: assigns all dates to the validation set.
1. `RandomSelector`: randomly draws a subset of dates _without_ replacement.
1. `PeriodicSelector`: draws contiguous subsets of days periodically from the collection.

See the [examples](https://invenia.pages.invenia.ca/research/DateSelectors.jl/examples.html) in the docs for more info.
