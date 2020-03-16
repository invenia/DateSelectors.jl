# Examples

## NoneSelector

The `NoneSelector` simply assigns all days to the validation set and none to the holdout set.

```@example dateselectors
using DateSelectors
using Dates

date_range = Date(2019, 1, 1):Day(1):Date(2019, 3, 31)

selector = NoneSelector()

validation, holdout = partition(date_range, selector)

collect(validation)
```

## RandomSelector

The `RandomSelector` subsamples the collection of dates and assigns them to the holdout set.
By default, the subsampling is performed uniformly but this can be changed by providing `weights` as positional argument.

**Note**: It is strongly recommended you explicitly provide the `seed` for reproducibility and to
differentiate your generated datasets from other those of other users.

Here we are drawing 15 days while setting the `seed` to 1.

```@example dateselectors
selector = RandomSelector(15, 1)

validation, holdout = partition(date_range, selector)

collect(validation)
```

## PeriodicSelector

The `PeriodicSelector` assigns holdout dates by taking a `stride` once per `period` starting from the start date + `offset`.

In this example - for whatever reason - we want to assign weekdays as validation days and weekends as holdout days.
Therefore, our `period` is `Week(1)` and `stride` is `Day(2)`.
However, 2019-1-1 is a Tuesday so we must first `offset` by `Day(4)` to start selecting on the first Saturday.

```@example dateselectors
selector = PeriodicSelector(Week(1), Day(2), Day(4))

validation, holdout = partition(date_range, selector)

collect(validation)
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

collect(validation)
```

as well as an `AbstractInterval`:

```@example dateselectors

selector = PeriodicSelector(Week(1), Day(2), Day(4))

date_range = AnchoredInterval{Day(90), Date}(Date(2019, 1, 1))

validation, holdout = partition(date_range, selector)

collect(validation)
```
