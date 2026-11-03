* BSIM4 drain and source diffusion resistance, RSH x NRD/NRS (rdsMod=0) and
* RSH with rdsMod=1, against ngspice 45: the terminal currents through the
* drain and source sources. Card a: the default level-54 card with RSH=20,
* rdsMod=0; card r: the same with rdsMod=1 (the bias-dependent Rd/Rs in
* series). Per card: a triode nfet with its junctions forward biased (VGS 1.2,
* VDS 0.05, VBS 0.6), a saturated nfet with m=2 and back bias (1.5, 2, -1), an
* nfet in reverse mode (drain 0.5 V under the source), a saturated pfet
* (VSG 1.5, VSD 2), NRD=1 NRS=1 on each; a saturated nfet with NRD=3 and no
* NRS (only the drain resistance), and one with no NRD/NRS, RGEOMOD=1 and
* NF=2 (the geometry-based resistance, DMCG = 0.5 um on every card).
* Oracle: ngspice 45 on this deck. Expected results: bsim4_rsh_nrd.expected.json
.options reltol=1e-8 vntol=1e-12 abstol=1e-18
.model na nmos level=54 rsh=20 dmcg=0.5u
.model pa pmos level=54 rsh=20 dmcg=0.5u
.model nr nmos level=54 rsh=20 rdsmod=1 dmcg=0.5u
.model pr pmos level=54 rsh=20 rdsmod=1 dmcg=0.5u
vda1 da1 0 0.05
vsa1 sa1 0 0
vga1 ga1 0 1.2
vba1 ba1 0 0.6
ma1 da1 ga1 sa1 ba1 na l=1u w=10u nrd=1 nrs=1
vda2 da2 0 2
vsa2 sa2 0 0
vga2 ga2 0 1.5
vba2 ba2 0 -1
ma2 da2 ga2 sa2 ba2 na l=1u w=10u nrd=1 nrs=1 m=2
vda3 da3 0 -0.5
vsa3 sa3 0 0
vga3 ga3 0 1.5
vba3 ba3 0 -1
ma3 da3 ga3 sa3 ba3 na l=1u w=10u nrd=1 nrs=1
vda4 da4 0 -2
vsa4 sa4 0 0
vga4 ga4 0 -1.5
vba4 ba4 0 0
ma4 da4 ga4 sa4 ba4 pa l=1u w=10u nrd=1 nrs=1
vda5 da5 0 2
vsa5 sa5 0 0
vga5 ga5 0 1.5
vba5 ba5 0 0
ma5 da5 ga5 sa5 ba5 na l=1u w=10u nrd=3
vda6 da6 0 2
vsa6 sa6 0 0
vga6 ga6 0 1.5
vba6 ba6 0 0
ma6 da6 ga6 sa6 ba6 na l=1u w=10u rgeomod=1 nf=2
vdr1 dr1 0 0.05
vsr1 sr1 0 0
vgr1 gr1 0 1.2
vbr1 br1 0 0.6
mr1 dr1 gr1 sr1 br1 nr l=1u w=10u nrd=1 nrs=1
vdr2 dr2 0 2
vsr2 sr2 0 0
vgr2 gr2 0 1.5
vbr2 br2 0 -1
mr2 dr2 gr2 sr2 br2 nr l=1u w=10u nrd=1 nrs=1 m=2
vdr3 dr3 0 -0.5
vsr3 sr3 0 0
vgr3 gr3 0 1.5
vbr3 br3 0 -1
mr3 dr3 gr3 sr3 br3 nr l=1u w=10u nrd=1 nrs=1
vdr4 dr4 0 -2
vsr4 sr4 0 0
vgr4 gr4 0 -1.5
vbr4 br4 0 0
mr4 dr4 gr4 sr4 br4 pr l=1u w=10u nrd=1 nrs=1
vdr5 dr5 0 2
vsr5 sr5 0 0
vgr5 gr5 0 1.5
vbr5 br5 0 0
mr5 dr5 gr5 sr5 br5 nr l=1u w=10u nrd=3
vdr6 dr6 0 2
vsr6 sr6 0 0
vgr6 gr6 0 1.5
vbr6 br6 0 0
mr6 dr6 gr6 sr6 br6 nr l=1u w=10u rgeomod=1 nf=2
.save i(vda1) i(vsa1) i(vda2) i(vsa2) i(vda3) i(vsa3) i(vda4) i(vsa4)
+ i(vda5) i(vsa5) i(vda6) i(vsa6) i(vdr1) i(vsr1) i(vdr2) i(vsr2)
+ i(vdr3) i(vsr3) i(vdr4) i(vsr4) i(vdr5) i(vsr5) i(vdr6) i(vsr6)
.op
.end
