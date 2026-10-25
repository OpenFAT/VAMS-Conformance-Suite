//! inherited IEEE 1364-2005 6.1.3 7.14 A.2.2.3
// §7.14: a delay3 is (rise, fall); each value of a continuous assignment's
// delay may be a variable, evaluated when the change is scheduled. Every value
// after the first is a variable here too (ivtest rise_fall_delay1/2,
// pr2728032 crashed on it). Reference: iverilog -g2005 prints these lines.
module assign_variable_rise_fall_delay;
  reg [31:0] dr, df;
  reg x;
  wire y;

  assign #(dr, df) y = x;

  initial begin
    dr = 2;
    df = 5;
    x = 0;
    #10 x = 1;
    #1 $display("t11 %b", y);
    #1 $display("t12 %b", y);
    x = 0;
    #4 $display("t16 %b", y);
    #1 $display("t17 %b", y);
  end
endmodule
