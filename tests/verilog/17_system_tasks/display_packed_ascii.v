// IEEE1364-2005 17.1.1.2/.7: numeric argument contains packed8-bit ASCII.
// §17.1.1.7: "No termination character or value is required at the end of a
// string": 24'h414243 -> "ABC". (No leading zero byte: whether one leaves a
// blank column, the clause does not say.)
// Numeric literal isolates %s from unsupported string-valued expressions.
//! inherited IEEE 1364-2005 17.1.1.2 17.1.1.7
//! expect stdout display_packed_ascii.expected.txt
module audit_display_packed_ascii;
  initial begin
    $display("string=[%s]", 24'h414243);
    $display("upper=[%S]", 24'h444546);
    $display("char=[%c][%C]", 8'h5a, 8'h21);
    $finish(0);
  end
endmodule
