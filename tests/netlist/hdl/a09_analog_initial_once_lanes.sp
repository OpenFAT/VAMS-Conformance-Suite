* A09 as GPU transient lanes: the analog initial block of every lane runs ONCE
* (LRM 5.2.1), so v(ini) = 1.0 at every accepted point of every .step point.
* The 60-node RC ladder gives the lanes a sparse LU tape, so under --backend
* cuda the .step points batch as GPU transient lanes with the runtime .hdl
* model resident. Only a non-Debug cuda run exercises that path: Debug never
* puts a runtime .hdl model on the device (src/device/hdl_gpu.zig enabled),
* and on the CPU the deck checks the host latch alone.
* Before the fix this deck panicked on cuda (attempt to use null value), and
* a lane's state pass would rerun the block on every step.
* Expected results: a09_analog_initial_once_lanes.expected.json
.hdl "a09_analog_initial_once.assets/a09_initial_once.va"
.param rl=1k
N1 ini 0 a09_initial_once
R1 ini 0 {rl}
V1 n0 0 PULSE(0 1 0 0.1 0.1 0.3 1)
RL0 n0 n1 {rl}
CL0 n1 0 1u
RL1 n1 n2 {rl}
CL1 n2 0 1u
RL2 n2 n3 {rl}
CL2 n3 0 1u
RL3 n3 n4 {rl}
CL3 n4 0 1u
RL4 n4 n5 {rl}
CL4 n5 0 1u
RL5 n5 n6 {rl}
CL5 n6 0 1u
RL6 n6 n7 {rl}
CL6 n7 0 1u
RL7 n7 n8 {rl}
CL7 n8 0 1u
RL8 n8 n9 {rl}
CL8 n9 0 1u
RL9 n9 n10 {rl}
CL9 n10 0 1u
RL10 n10 n11 {rl}
CL10 n11 0 1u
RL11 n11 n12 {rl}
CL11 n12 0 1u
RL12 n12 n13 {rl}
CL12 n13 0 1u
RL13 n13 n14 {rl}
CL13 n14 0 1u
RL14 n14 n15 {rl}
CL14 n15 0 1u
RL15 n15 n16 {rl}
CL15 n16 0 1u
RL16 n16 n17 {rl}
CL16 n17 0 1u
RL17 n17 n18 {rl}
CL17 n18 0 1u
RL18 n18 n19 {rl}
CL18 n19 0 1u
RL19 n19 n20 {rl}
CL19 n20 0 1u
RL20 n20 n21 {rl}
CL20 n21 0 1u
RL21 n21 n22 {rl}
CL21 n22 0 1u
RL22 n22 n23 {rl}
CL22 n23 0 1u
RL23 n23 n24 {rl}
CL23 n24 0 1u
RL24 n24 n25 {rl}
CL24 n25 0 1u
RL25 n25 n26 {rl}
CL25 n26 0 1u
RL26 n26 n27 {rl}
CL26 n27 0 1u
RL27 n27 n28 {rl}
CL27 n28 0 1u
RL28 n28 n29 {rl}
CL28 n29 0 1u
RL29 n29 n30 {rl}
CL29 n30 0 1u
RL30 n30 n31 {rl}
CL30 n31 0 1u
RL31 n31 n32 {rl}
CL31 n32 0 1u
RL32 n32 n33 {rl}
CL32 n33 0 1u
RL33 n33 n34 {rl}
CL33 n34 0 1u
RL34 n34 n35 {rl}
CL34 n35 0 1u
RL35 n35 n36 {rl}
CL35 n36 0 1u
RL36 n36 n37 {rl}
CL36 n37 0 1u
RL37 n37 n38 {rl}
CL37 n38 0 1u
RL38 n38 n39 {rl}
CL38 n39 0 1u
RL39 n39 n40 {rl}
CL39 n40 0 1u
RL40 n40 n41 {rl}
CL40 n41 0 1u
RL41 n41 n42 {rl}
CL41 n42 0 1u
RL42 n42 n43 {rl}
CL42 n43 0 1u
RL43 n43 n44 {rl}
CL43 n44 0 1u
RL44 n44 n45 {rl}
CL44 n45 0 1u
RL45 n45 n46 {rl}
CL45 n46 0 1u
RL46 n46 n47 {rl}
CL46 n47 0 1u
RL47 n47 n48 {rl}
CL47 n48 0 1u
RL48 n48 n49 {rl}
CL48 n49 0 1u
RL49 n49 n50 {rl}
CL49 n50 0 1u
RL50 n50 n51 {rl}
CL50 n51 0 1u
RL51 n51 n52 {rl}
CL51 n52 0 1u
RL52 n52 n53 {rl}
CL52 n53 0 1u
RL53 n53 n54 {rl}
CL53 n54 0 1u
RL54 n54 n55 {rl}
CL54 n55 0 1u
RL55 n55 n56 {rl}
CL55 n56 0 1u
RL56 n56 n57 {rl}
CL56 n57 0 1u
RL57 n57 n58 {rl}
CL57 n58 0 1u
RL58 n58 n59 {rl}
CL58 n59 0 1u
RL59 n59 n60 {rl}
CL59 n60 0 1u
.step param rl list 1k 2k 3k 4k 5k 6k 7k 8k
.tran 0.01 1.0
.save v(ini) v(n60)
.end
