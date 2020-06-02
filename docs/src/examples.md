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

The `RandomSelector` subsamples the collection of dates and assigns them to the holdout set.
By default, the subsampling is performed uniformly but this can be changed by providing `weights` as positional argument.

Here we use a seed of `42`
to partition 10% of the data into the holdout set,
in 3-day blocks, some of which may be contiguous.

```@example dateselectors
selector = RandomSelector(42, 0.10, Day(3))

validation, holdout = partition(date_range, selector)

validation
```

## PeriodicSelector

The `PeriodicSelector` assigns holdout dates by taking a `stride` once per `period`.
Where in the period the holdout `stide` is taken from is determined by the `offset`.
The offset is relative to _Monday 1st Jan 1900_.

In this example - for whatever reason - we want to assign weekdays as validation days and weekends as holdout days.
Therefore, our `period` is `Week(1)` and `stride` is `Day(2)`, because out of every week we want to keep 2 days in the holdout.
Now since, we need to start selecting on the Saturday, so we must first `offset` by `Day(5)` to because zero offset corresponds to a Monday.

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
