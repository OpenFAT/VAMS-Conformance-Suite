* BSIM4 rdsMod=0 diffusion resistance RSH x NRD/NRS in .noise (tnoimod=0)
* The drain and source diffusion resistors (RSH = 10, NRD = NRS = 2: 20 ohm
* each) carry their thermal noise and set the gain, as ngspice's b4ld.c
* gdpr/gspr and b4noi.c's RD/RS noise. ESPice shorted them before.
* Oracle: ngspice 45 on this deck. Expected results: device_bsim4_noise_rsh_nrd.expected.json
VDD vdd 0 1.8
VG g 0 DC 0.9 AC 1
VB b 0 0
RL vdd d 5k
M1 d g 0 b n4 W=10u L=0.5u NF=1 M=1 NRD=2 NRS=2
.model n4 NMOS LEVEL=54 TNOIMOD=0 FNOIMOD=0 RDSMOD=0 RSH=10
.noise v(d) VG dec 3 10 10g
.end
