// IEEE 1364-2005 §18.1.1, p. 326: "The filename is optional and defaults to
// the literal string dump.vcd if not specified."
//
// No $dumpfile runs at all, so $dumpvars dumps into dump.vcd in the working
// directory; the golden is read from that file. (Each run of this fixture
// has a working directory of its own, so the common name clashes with no
// other fixture's dump.)
//
// HAND DERIVATION (the gold's codes run from `!` in $var order; the
// comparison, `//! expect vcd`, sets aside codes and order, the writer's):
//   $dumpvars(1, <this module>) selects its two variables, in declaration
//   order: a -> !, v -> ".
//   #0 $dumpvars: a = 1, v = 2'b01 (assigned in the same time unit, after
//   the call; dumping starts at its end, §18.1.3): 1! and b1 " (the leading
//   0 extends the 1 and drops, Table 18-1).
//   #1 v = 2'b10 -> b10 ".
// gold: Icarus Verilog 13.0 agrees (through //! expect vcd's canonical compare)
//! inherited IEEE 1364-2005 18.1.1
//! expect vcd dump.vcd == dumpfile_default_name.expected.vcd
`timescale 1ns/1ns
module b_18_1_1_dumpfile_default_name;
  reg a;
  reg [1:0] v;
  initial begin
    $dumpvars(1, b_18_1_1_dumpfile_default_name);
    a = 1'b1;
    v = 2'b01;
    #1 v = 2'b10;
    $finish(0);
  end
endmodule
