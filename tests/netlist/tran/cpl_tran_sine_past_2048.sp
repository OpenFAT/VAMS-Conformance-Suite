* CPL history past its 2048-point capacity on a curved waveform, sampled every
* 0.1 ns. Past the capacity coupled_ltra.va drops the interior point whose
* linear interpolation loses least, read from a per-point loss cache (hb[k],
* ESPice 992bf304) that must be refreshed wherever a point or a neighbour
* changes. On cpl_tran_history_past_2048's PULSE plateaus every interior loss
* is 0, fresh or stale; a sine is curved everywhere.
* The line is cpl_tran_history_past_2048's, driven in even mode: both
* conductors from one source through 100 ohm each, 100 ohm loads.
*   Le = 250n + 150n = 400 nH/m, Ce = 100p - 60p = 40 pF/m,
*   Ze = sqrt(Le/Ce) = 100 ohm (matched), Td = 2 m * sqrt(Le*Ce) = 8 ns,
*   forced dt = 1 ps, so the far end reads 8000 accepted points back.
*   v(a1)(t) = v(a2)(t) = 0.5 sin(2 pi f t),  f = 312.5 MHz
*   v(b1)(t) = v(b2)(t) = 0.5 sin(2 pi f (t - Td)) = -v(a1)(t) for t > Td
*   (2.5 periods), 0 before.
* Rows: t = 4 ns (before the wavefront), then 8.1 ns to 16 ns every 0.1 ns
* (81 rows).
* Tolerance: v(a) atol 5e-6 (interpolation bound 2.4e-7 at h = 1 ps); v(b)
* atol 1e-3: the CPL model itself sits up to 2.7e-4 V off the ideal delay.
* Measured (ESPice test/tline-cache):
*   ngspice-45 on this netlist: v(b1) within 2.75e-4 of every row.
*   ESPice 5275c0d3: within 2.75e-4, and within 6.3e-5 of ngspice-45.
*   coupled_ltra.va with the loss refresh around a dropped point removed:
*   v(b1) 0.139 V off (67 rows over); dropping the point chosen at the
*   previous compaction: 1.98e-2 off.
* Expected results: cpl_tran_sine_past_2048.expected.json
Vs in 0 SIN(0 1 312.5meg)
Rs1 in a1 100
Rs2 in a2 100
P1 a1 a2 0 b1 b2 0 cmod
RL1 b1 0 100
RL2 b2 0 100
.model cmod CPL
+R = 1e-6 0 1e-6
+L = 250n 150n
+     250n
+C = 100p -60p
+     100p
+G = 0 0 0
+length = 2
.tran 1p 16n 0 1p
.end
