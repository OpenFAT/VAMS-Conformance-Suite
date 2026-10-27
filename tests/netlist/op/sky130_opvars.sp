* sky130 BSIM4 device operating-point variables (#236): @m[id], [gm], [gds],
* [vth] and [vdsat] of an nfet and a pfet in saturation, at the operating
* point and along a two-point .dc of the nfet's gate. The @dev[param] names
* are ngspice's dialect. Oracle: ngspice 45 on this deck, confirmed by Xyce.
* Expected results: sky130_opvars.expected.json
.include '../regression/ota_buffer_large_step.assets/sky130_fet01v8_tt.spice'
vdn dn 0 1.2
vgn gn 0 0.9
xn dn gn 0 0 sky130_fd_pr__nfet_01v8 w=6 l=0.8
vdd vdd 0 1.8
vdp dp 0 0.6
vgp gp 0 0.9
xp dp gp vdd vdd sky130_fd_pr__pfet_01v8 w=2.61 l=0.5
.save v(dn) v(gn)
+ @m.xn.msky130_fd_pr__nfet_01v8[id] @m.xn.msky130_fd_pr__nfet_01v8[gm]
+ @m.xn.msky130_fd_pr__nfet_01v8[gds] @m.xn.msky130_fd_pr__nfet_01v8[vth]
+ @m.xn.msky130_fd_pr__nfet_01v8[vdsat]
+ @m.xp.msky130_fd_pr__pfet_01v8[id] @m.xp.msky130_fd_pr__pfet_01v8[gm]
+ @m.xp.msky130_fd_pr__pfet_01v8[gds] @m.xp.msky130_fd_pr__pfet_01v8[vth]
+ @m.xp.msky130_fd_pr__pfet_01v8[vdsat]
.op
.dc vgn 0.8 0.9 0.1
.end
