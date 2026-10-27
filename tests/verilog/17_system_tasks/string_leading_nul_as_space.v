//! inherited IEEE 1364-2005 17.1.1.7 17.2.3
// §17.1.1.7: %s's argument is "a sequence of 8-bit hexadecimal ASCII codes",
// and "leading zeros are never printed." Whether a leading zero byte leaves a
// blank column or no column the clause does not say; that it is not printed,
// as a NUL or as anything else, it does.
//
// s, 64 bits, holds "Hello" after three zero bytes. $swrite (§17.2.3, the
// $fwrite family into a reg) writes "[%s]" of it into t, wide enough for
// either reading, and t is padded on the left with zeros (§5.2.3.2).
// Scanning t from its leftmost byte, the first nonzero byte is "[", no zero
// byte follows it, and t ends in "Hello]": "first=[ nul=0 tail=1".
module triage_string_leading_nul_as_space;
  reg [8*8-1:0] s;
  reg [8*16:1] t;
  reg [7:0] c, first;
  integer i, nul, seen;

  initial begin
    s = "Hello";
    $swrite(t, "[%s]", s);
    first = 0; nul = 0; seen = 0;
    for (i = 16; i >= 1; i = i - 1) begin
      c = t[8*i -: 8];
      if (c != 0 && !seen) begin seen = 1; first = c; end
      else if (c == 0 && seen) nul = 1;
    end
    $display("first=%s nul=%0d tail=%0d", first, nul, t[8*6:1] == "Hello]");
  end
endmodule
