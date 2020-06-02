
"""
    _determine_initial_time(s::S, dates) where S<: DateSelector

Determines when we start counting from when breaking `dates` up into blocks.
Checks that that initial time is valid for the given `dates`.
"""
function _determine_initial_time(s::S, dates) where S<: DateSelector
    sd, ed = extrema(dates)

    # The order from FERC that created the US ISO's (the first of their kind) came in 1999
    # thus seems safe to start in 1900, which has the convient feature of
    # starting on a Monday
    beginning_of_time = Date(1900)
    initial_time = beginning_of_time + s.offset
    sd < initial_time && throw(DomainError(
        sd,
        "$S with offset $(s.offset) cannot be used before $(initial_time)",
    ))
    return initial_time
end

function _generate_block_starts(s::DateSelector, block_size, dates)
    sd, ed = extrema(dates)


end
