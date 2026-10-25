//! inherited IEEE 1364-2005 17.1.1.3
// A field width like %04d is outside §17.1.1.3's automatic sizing and its %0
// override, and §17.1.1.2 grants C's '0' flag to the real conversions only,
// so the clause leaves the padding open. VerA zero-fills it after any sign,
// as iverilog does (oracle: iverilog -g2005; ivtest test_extended's `%08d`
// and delay.v's `%04d` golds).
module triage_decimal_field_width_zero_padded;
  initial $display("[%04d]", 7);
endmodule
