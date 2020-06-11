
# Examples

## NoneSelector

The `NoneSelector` simply assigns all days to the validation set and none to the holdout set.

```@example dateselectors
using DateSelectors
using Dates

date_range = Date(2019, 1, 1):Day(1):Date(2019, 3, 31)

selector = NoneSelector()

validation, holdout = partition(date_range, selector)

validation
```

## RandomSelector

The `RandomSelector` uniformly subsamples the collection of dates and assigns them to the holdout set.

Here we use a seed of `42` to uniformly sample from the  date range with probability 10% into the holdout set,
in 3-day blocks, some of which may be contiguous.
Note that for a given seed and date range the portion in the holdout set may not be exactly 10% as it is a random sample.

The selection, while random, is fully determined by the `RandomSelector` object and is invariant on the date range.
That is to say if one has two distinct but overlapping date ranges, and uses the same `RandomSelector` object, then the overlapping days will consistently be placed into either holdout or validation in both.

```@example dateselectors
selector = RandomSelector(42, 0.10, Day(3))

validation, holdout = partition(date_range, selector)

validation
```

## PeriodicSelector

The `PeriodicSelector` assigns holdout dates by taking a `stride` once per `period`.
Where in the period the holdout `stride` is taken from is determined by the `offset`.
The offset is relative to _Monday 1st Jan 1900_.

As the stride start location is relative to a fixed point rather than to the date range, this means that the selection, is fully determined by the `PeriodicSelector` object and is invariant on the date range.
That is to say if one has two distinct but overlapping date ranges, and uses the same `PeriodicSelector` object, then the overlapping days will consistently be placed into either holdout or validation in both.

In this example - for whatever reason - we want to assign weekdays as validation days and weekends as holdout days.
Therefore, our `period` is `Week(1)` and `stride` is `Day(2)`, because out of every week we want to keep 2 days in the holdout.
Now, since we need to start selecting on the Saturday, we must first `offset` by `Day(5)` because zero offset corresponds to a Monday.

```@example dateselectors
selector = PeriodicSelector(Week(1), Day(2), Day(5))

validation, holdout = partition(date_range, selector)

validation
```

We can verify that it returned what we expected:
```@example dateselectors
unique(dayname.(validation))
```
```@example dateselectors
unique(dayname.(holdout))
```


## Using AbstractIntervals

You can also specify the date range as an `Interval`:

```@example dateselectors
using Intervals

selector = PeriodicSelector(Week(1), Day(2), Day(4))

date_range = Date(2018, 1, 1)..Date(2019, 3, 31)

validation, holdout = partition(date_range, selector)

validation
```

as well as an `AbstractInterval`:

```@example dateselectors

selector = PeriodicSelector(Week(1), Day(2), Day(4))

date_range = AnchoredInterval{Day(90), Date}(Date(2019, 1, 1))

validation, holdout = partition(date_range, selector)

validation
```
