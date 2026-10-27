* A P-channel VDMOS conducts with the mirrored square law: Vgs = -5 V,
* VTO = -1 V, Vds = -5 V puts it in saturation (|Vds| >= |Vgs - VTO| = 4 V),
* so |Id| = KP/2 (Vgs - VTO)^2 = 0.5*16 = 8 A, flowing from the source (0)
* into the drain node and through vd from d to 0: i(vd) = +8 A. The body
* diode is reverse biased by 5 V (IS 1e-14 A).
* Expected results: vdmos_pchan_saturation.expected.json
VD d 0 -5
VG g 0 -5
M1 d g 0 vm
.model vm vdmos pchan vto=-1 kp=1
.op
.end
