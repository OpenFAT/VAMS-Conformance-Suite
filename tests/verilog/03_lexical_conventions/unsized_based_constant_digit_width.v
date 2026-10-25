// IEEE 1364-2005 §3.5.1: "The number of bits that make up an unsized number
// (which is a simple decimal number or a number without the size
// specification) shall be at least 32." The clause gives only a floor, so how
// wide an unsized based constant with more than 32 bits of digits is, is
// open. VerA makes it as wide as its digits (digit count times bits per
// digit, leading zero digits included), as iverilog -g2005 does (the oracle;
// ivtest pr903, which this fixture truncated to 32 bits until 2026-10-24;
// specification/Vague_Decisions.md VD-129).
//
//   'h1_0000_0000          9 hex digits, 36 bits  -> %h 100000000
//   'h0000_0000_0001       12 digits, 48 bits     -> %h 000000000001
//   'hf                    4 bits, floored at 32  -> %h 0000000f
//   'h9000_0000_0000_0000_0000 / 'h3000_0000_0000_0000_0000
//                          80 bits each, so no digit is lost: 3
//   -'h1_0000_0000         36 bits: 2^36 - 2^32   -> %h f00000000
//! inherited IEEE 1364-2005 3.5.1
module b_3_5_1_unsized_based_constant_digit_width;
  initial begin
    $display("%h", 'h1_0000_0000);
    $display("%h", 'h0000_0000_0001);
    $display("%h", 'hf);
    $display("%0d", 'h9000_0000_0000_0000_0000 / 'h3000_0000_0000_0000_0000);
    $display("%h", -'h1_0000_0000);
  end
endmodule
