// IEEE 1364-2005 §5.5.4, p. 66: "If any bit of a signed value is X or Z, then
// any nonlogical operation involving the value shall result in the entire
// resultant value being an X". "Nonlogical" is not defined, so a bitwise
// operator or `?:` on a signed operand holding x may follow either that
// sentence (all x) or its own bit table (§5.1.10, §5.1.13 Table 5-21). Every
// conforming reading gives one of the two, and this checks exactly that.
//
// Every operand is 4 bits and the target is `reg signed [3:0]`, so nothing is
// resized. Bit table result, else all x:
//   4'sb10x1 & 4'sb0000 -> 0000
//   4'sb10x1 | 4'sb0000 -> 10x1
//   4'sb10x1 ^ 4'sb0000 -> 10x1
//   ~4'sb10x1           -> 01x0
//   1'bx ? 4'sb10x1 : 4'sb10x1 -> 10x1 (Table 5-21 keeps equal bits)
// Each line prints 1 when the result is one of its two values.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 5.5.4
module b_5_5_4_signed_unknown_bitwise;
  reg signed [3:0] e;
  initial begin
    e = 4'sb10x1 & 4'sb0000; $write("%b ", e === 4'b0000 || e === 4'bxxxx);
    e = 4'sb10x1 | 4'sb0000; $write("%b ", e === 4'b10x1 || e === 4'bxxxx);
    e = 4'sb10x1 ^ 4'sb0000; $write("%b ", e === 4'b10x1 || e === 4'bxxxx);
    e = ~4'sb10x1; $write("%b ", e === 4'b01x0 || e === 4'bxxxx);
    e = 1'bx ? 4'sb10x1 : 4'sb10x1; $display("%b", e === 4'b10x1 || e === 4'bxxxx);
    $finish(0);
  end
endmodule
