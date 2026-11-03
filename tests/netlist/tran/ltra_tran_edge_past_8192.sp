* LTRA history past its 8192-point capacity across a 10 ps edge. Past the
* capacity ltra.va drops the first straight interior point, else the least
* bent, read from a per-point bend cache (hb[k], ESPice 51f3ed29) that must be
* refreshed wherever a point or a neighbour changes. A history that keeps the
* edge's corners reproduces the delayed edge exactly at accepted points; one
* that drops a corner does not. ltra_tran_long_run_past_8192 (a sine, no
* corners) moves by 7e-8 under a cache that is never refreshed for new points.
* The line is ltra_tran_long_run_past_8192's, driven by a PULSE:
*   Td = len*sqrt(l*c) = 2 m * 5 ns/m = 10 ns, forced dt = 1 ps, so the far end
*   reads 10000 accepted points back, 1808 past the bound.
*   Z0 = 50 ohm = Rs = RL, alpha*len = 2e-8 Np (inside rtol).
*   v(a)(t) = 0.5 ramp from 6 ns to 6.01 ns;  v(b)(t) = v(a)(t - Td)
* Rows (the far-end ones on accepted points, where the ramp is the closed form):
*   t =  3 ns          v(a) = 0    v(b) = 0
*   t = 15.9995 ns     v(a) = 0.5  v(b) = 0
*   t = 16.0015 ns     v(a) = 0.5  v(b) = 0.075
*   t = 16.0095 ns     v(a) = 0.5  v(b) = 0.475
*   t = 16.0105 ns     v(a) = 0.5  v(b) = 0.5
*   t = 16.5 ns        v(a) = 0.5  v(b) = 0.5
* The rows sit on accepted times, so a change to the step grid moves them.
* Measured (ESPice test/tline-cache):
*   ngspice-45 and ESPice 5275c0d3 on this netlist: every row to 1e-8.
*   ltra.va with the bend refresh of the new tail removed: v(b) = 0.50278 at
*   16.0105 ns (the top corner dropped); dropping the point chosen at the
*   previous timepoint: v(b) = 0.0050 at 15.9995 ns, before the edge.
* Expected results: ltra_tran_edge_past_8192.expected.json
Vin in 0 PULSE(0 1 6n 10p 10p 500n 1u)
Rs in a 50
O1 a 0 b 0 lline
RL b 0 50
.model lline LTRA(r=1e-6 l=250n g=0 c=100p len=2 rel=1 compactrel=1e-30 compactabs=1e-30)
.tran 1p 17n 0 1p
.end
