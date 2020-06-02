module DateSelectors

using Base.Iterators
using Dates
using Intervals
using Random

export DateSelector, NoneSelector, PeriodicSelector, RandomSelector, partition

include("common.jl")
include("NoneSelector.jl")
include("PeriodicSelector.jl")
include("RandomSelector.jl")

include("deprecated.jl")

end
