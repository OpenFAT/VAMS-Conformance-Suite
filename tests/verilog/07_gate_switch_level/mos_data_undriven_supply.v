// IEEE 1364-2005 §3.7.4: "The supply0 and supply1 nets can be used to model
// the power supplies in a circuit. These nets shall have supply strengths."
// They have no driver; §7.12 (Table 7-11) passes a MOS switch's data
// strength to its output, supply reduced to strong. So a switch whose data
// terminal is a bare supply net drives that net's value from time 0, with no
// other reader of the supply net needed. (VerA once read an undriven net's
// strength as high impedance until something resolved it: `y`, `z` and `w`
// below all read z. Oracle: iverilog -g2005 prints these lines.)
//
// HAND DERIVATION. a = 1: the nmos instances conduct gnd's 0 at strong
// (St0), the pmos ones are off. a = 0: the pmos instances conduct vdd's 1
// (St1); `w`'s lone nmos is off, so w is z. The #2 pair has settled by the
// #10 reads.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 3.7.4 7.12
module b_7_12_mos_data_undriven_supply;
  supply0 gnd;
  supply1 vdd;
  reg a;
  wire y, z, w;
  nmos n(y, gnd, a);
  pmos p(y, vdd, a);
  nmos #2 n2(z, gnd, a);
  pmos #2 p2(z, vdd, a);
  nmos (w, gnd, a);
  initial begin
    a = 1;
    #10 $display("%b %b %b %v", y, z, w, y);
    a = 0;
    #10 $display("%b %b %b %v", y, z, w, y);
  end
endmodule
