// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.1.1.2
// %x is not in 1364-2005 Table 17-3; IEEE 1800-2017 §21.2.1.2 Table 21-1
// adds "%x or %X" as an alias of %h, and iverilog (-g2005, the reference
// tool for ivtest's string13, mem1, pr245 ...) accepts it in 1364 mode. VerA
// takes it as the same alias: sized and rendered exactly as %h.
module percent_x_alias;
  reg [7:0] a;
  reg [11:0] b;
  initial begin
    a = 8'h5a;
    b = 12'b1010_xxxx_zzzz;
    $display("%x %X %h|%0x|%x", a, a, a, a, b);
  end
endmodule
