//! inherited IEEE 1364-2005 7.1.6
// §7.1.6 sizes terminals only for instance arrays; what a single gate makes
// of a multi-bit input expression the standard leaves open. Where it is
// silent VerA does what the reference tool does: iverilog, and by its
// gate_connect1 the other simulators, read the expression's LSB. (This
// fixture refused the design until the conformance pass made the reference
// the tie-break.)
//
// HAND DERIVATION: b0 reads in's bit 0 (1), b1 reads 2'b10's bit 0 (0), b2
// reads 32-bit 3's bit 0 (1): "out=101" (out[2] first).
module triage_gate_multibit_input_lsb;
  reg [1:0] in;
  wire [2:0] out;

  buf b0(out[0], in);
  buf b1(out[1], 2'b10);
  buf b2(out[2], 3);

  initial begin
    in = 2'b01;
    #1 $display("out=%b", out);
  end
endmodule
