// IEEE 1364-2005 §17.1.1.3 sizes a displayed value by the largest value its
// expression can take; §4.8.2 converts a real to an integer by rounding, half
// away from zero. Neither clause, nor VAMS §9.4.3, says how wide the integer
// a real becomes under %d is: a real has no bit width to size by. The digital
// engine prints it at minimal width, as if `%0d`, as iverilog does
// (specification/Vague_Decisions.md VD-120; oracle: iverilog -g2005, whose
// output this file matches byte for byte). The `$rtoi` line is the contrast:
// §17.8 returns an `integer`, 32 bits signed, which %d sizes as usual.
//
// HAND DERIVATION.
//   %d   of 7 / 2.0   3.5 rounds away from zero to 4   -> [4]
//   %0d  of 7 / 2.0   the same                          -> [4]
//   %d   of -2.5      rounds to -3                      -> [-3]
//   %d   of -9.2e18   exact in a double (92 * 10^17 is a multiple of 1024,
//                     the spacing below 2^63)           -> [-9200000000000000000]
//   %d   of $rtoi(3.5)  truncates to 3, an integer: n = 32, 2147483648 is
//                     10 digits plus a sign column: 10 spaces, "3"
//! inherited IEEE 1364-2005 17.1.1.3
//! expect stdout decimal_of_real_width.expected.txt
module b_17_1_1_3_decimal_of_real_width;
  real r;
  initial begin
    r = -9.2e18;
    $display("[%d]", 7 / 2.0);
    $display("[%0d]", 7 / 2.0);
    $display("[%d]", -2.5);
    $display("[%d]", r);
    $display("[%d]", $rtoi(3.5));
  end
endmodule
