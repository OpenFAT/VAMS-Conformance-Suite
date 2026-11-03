* TXL history past its 2048-point capacity on a curved waveform, sampled every
* 0.1 ns. Past the capacity txl.va drops the interior point whose linear
* interpolation loses least, read from a per-point loss cache (hb[k], ESPice
* fcfab5ec) that must be refreshed wherever a point or a neighbour changes.
* On txl_tran_long_run_past_2048's PULSE plateaus every interior loss is 0,
* fresh or stale, so a stale cache picks the same points there. A sine is
* curved everywhere: every drop depends on the cached losses.
*   Td = length*sqrt(L*C) = 1 m * 5 ns/m = 5 ns, forced dt = 1 ps (tmax = 1 ps),
*   so the far end reads 5000 accepted points back, 2952 past the bound.
* Z0 = sqrt(250n/100p) = 50 ohm, Rs = RL = Z0, GammaS = GammaL = 0: a pure
* delay of the matched divider (alpha*len = R/(2 Z0) = 1e-8 Np).
*   v(a)(t) = 0.5 sin(2 pi f t),  f = 500 MHz
*   v(b)(t) = 0.5 sin(2 pi f (t - Td)) = -v(a)(t) for t > Td (2.5 periods), 0 before
* Rows: t = 2 ns (v(b) = 0, before the wavefront), then 5.1 ns to 13 ns every
* 0.1 ns (81 rows).
* Tolerance: v(a) atol 5e-6, 8x the (h^2/8)|v''| = 6.2e-7 interpolation bound
* at h = 1 ps. v(b) atol 1e-3: the TXL model itself (ngspice's fit, which
* txl.va ports) sits up to 4.5e-4 V off the ideal delay by 13 ns.
* Measured (ESPice test/tline-cache):
*   ngspice-45 on this netlist: v(b) within 4.47e-4 of every row, v(a) 6.2e-7.
*   ESPice 5275c0d3: within 4.47e-4, and within 2.8e-5 of ngspice-45.
*   txl.va with the loss refresh around a dropped point removed: v(b) 5.2e-2
*   off (35 rows over); dropping the point chosen at the previous compaction:
*   1.05e-2 off.
* Expected results: txl_tran_sine_past_2048.expected.json
Vin in 0 SIN(0 1 500meg)
Rs in a 50
Y1 a 0 b 0 ymod
RL b 0 50
.model ymod txl R=1e-6 L=250n G=0 C=100p length=1
.tran 1p 13n 0 1p
.end
