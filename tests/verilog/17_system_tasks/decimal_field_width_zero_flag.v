//! inherited IEEE 1364-2005 17.1.1.3
// A field width like %04d is outside the clause's automatic sizing and its
// %0 override, and §17.1.1.2 grants C's flags to the real conversions only,
// so 1364 leaves the leading 0 of %04d open. VerA reads it as C's 0 flag and
// pads with zeros, as iverilog -g2005 does (the oracle; ivtest test_extended;
// specification/Vague_Decisions.md VD-129). %4d, no flag, pads with spaces,
// and a negative value keeps its sign in front of the zeros.
module triage_decimal_field_width_zero_flag;
  initial begin
    $display("[%04d]", 7);
    $display("[%4d]", 7);
    $display("[%05d]", -7);
    $display("[%04h]", 8'ha);
  end
endmodule
