# DateSelectors

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.pages.invenia.ca/DateSelectors.jl/)
[![Build Status](https://gitlab.invenia.ca/invenia/DateSelectors.jl/badges/master/build.svg)](https://gitlab.invenia.ca/invenia/DateSelectors.jl/commits/master)
[![Coverage](https://gitlab.invenia.ca/invenia/DateSelectors.jl/badges/master/coverage.svg)](https://gitlab.invenia.ca/invenia/DateSelectors.jl/commits/master)


# Usage

DateSelectors simplify the separation of [non-contiguous dates](https://gitlab.invenia.ca/invenia/wiki/blob/ml-best-practice/research/ml-best-practice/glossary.md#contiguous-and-stratified-datasets) for testing models.
To test on the first week in each month in a block of dates, the code would look something like this in the backrun script:

```julia
selector = PeriodicSelector(Month(1), Week(1))
dates = partition(selector, args.start_date, args.end_date)

results = pmap(dates.test) do date
    backrun_day(agent, client, date)
end
```
