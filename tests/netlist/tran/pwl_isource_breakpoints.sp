* PWL current source corners: a simulator must land on each corner of the
* PWL table, or v(a) at the corner times misses the exact RC response.
* Expected results: pwl_isource_breakpoints.expected.json
* Oracle: exact over each linear piece of I1 into 1k || 1n, sampled at
* ngspice's accepted times (which include every corner).
I1 0 a PWL(0 0 0.33u 1m 0.71u -1m 1.3u 0.5m)
R1 a 0 1k
C1 a 0 1n
.tran 0.1u 2u
.end
