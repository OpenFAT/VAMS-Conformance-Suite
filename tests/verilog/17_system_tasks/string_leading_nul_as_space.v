//! inherited IEEE 1364-2005 17.1.1.7
// %s prints the string's bytes, "and leading zeros are never printed": the
// three zero bytes before "Hello" in the 64-bit reg are not printed as
// characters but shown as spaces, so %s keeps the reg's width of 8
// characters, and %0s drops them. This is iverilog -g2005's text (the
// oracle; ivtest br_gh827, string5, string13;
// specification/Vague_Decisions.md VD-127). An inner zero byte is a space
// under both.
module triage_string_leading_nul_as_space;
  reg [8*8-1:0] s;

  initial begin
    s = "Hello";
    $display("[%s]", s);
    $display("[%0s]", s);
    s = 64'h00_00_00_61_00_62;
    $display("[%s]", s);
    $display("[%0s]", s);
  end
endmodule
