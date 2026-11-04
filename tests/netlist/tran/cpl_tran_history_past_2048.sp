* CPL even mode (cpl_tran_even_mode's line) run at a forced 1 ps step, so the
* 8 ns delay reads an entry ~8000 accepted points back, past the 2048-point
* history capacity of coupled_ltra.va (#105).
* Matched even mode, Ze = 100 ohm, Td = 8 ns: the 6 ns source edge reaches the
* far end at 14 ns.
*   t =  4.0 ns  v(a1)=0    v(b1)=0
*   t = 10.0 ns  v(a1)=0.5  v(b1)=0
*   t = 13.9 ns  v(a1)=0.5  v(b1)=0    (100 ps before arrival)
*   t = 14.2 ns  v(a1)=0.5  v(b1)=0.5
*   t = 15.9 ns  v(a1)=0.5  v(b1)=0.5
* Dropping the oldest live entry when the history fills publishes the edge at
* about 6 ns + 2048 ps + Td instead.
* Edge rows (ESPice test/tline-cache): the far end follows the 10 ps source
* ramp Td later, so at the accepted points 1.5 ps and 9.5 ps into it
*   t = 14.0015 ns  v(b1)=v(b2)=0.075     t = 14.0095 ns  v(b1)=v(b2)=0.475
* Those are the points one step inside the corners: a history that drops a
* corner reads 0.0625 and 0.4625 there. ESPice with coupled_ltra.va's
* drop-loss refresh of the new tail removed (ESPice 992bf304's hb[k]) does
* exactly that; the five rows above stay green under it. ngspice-45 and ESPice
* 5275c0d3 give both values to 1.4e-13. The rows sit on accepted times, so a
* change to the step grid moves them.
Vs in 0 PULSE(0 1 6n 10p 10p 500n 1u)
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
