"""
    NoneSelector()

Assign all dates to the validation set, select no holdout dates.
"""
struct NoneSelector <: DateSelector end

Iterators.partition(dates::StepRange{Date, Day}, ::NoneSelector) = _getdatesets(dates, Date[])
