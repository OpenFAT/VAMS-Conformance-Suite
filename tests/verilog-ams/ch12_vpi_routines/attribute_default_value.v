// The design attribute_default_value.c reads (VAMS-2023 2.9, IEEE 1364-2005
// 3.8 and 26.6.42). No `//!` directive, so the suite does not collect it.
//
// `conform_flag` is assigned no value, so 2.9 makes its value 1;
// `conform_level` is assigned 5, the control that the value is read at all.
`timescale 1ns/1ns

module attribute_default_value;
  (* conform_flag *) reg r;
  (* conform_level = 5 *) reg q;

  initial begin
    r = 1'b0;
    q = 1'b0;
    #1 $finish(0);
  end
endmodule
