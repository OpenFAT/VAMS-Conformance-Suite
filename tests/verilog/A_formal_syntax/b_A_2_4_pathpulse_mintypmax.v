// IEEE 1364-2005 A.2.4 and Syntax 14-7 derive each PATHPULSE$ limit through
// limit_value ::= constant_mintypmax_expression. Both the single-limit and
// two-limit forms therefore accept minimum:typical:maximum expressions.
// The limits apply (§14.6.1), but the constant input makes no pulse to
// filter: this test asserts the legal declaration and the buffer, whose
// input 1 reaches y through the 1 ns path at t=1, so the t=2 sample reads y=1
// (a t=1 sample would race the update, §11.4.2).
// The invalid neighbour is b_A_2_4_pathpulse_missing_corner_rejected.v.
// gold: Verilator 5.052 agrees
//! inherited IEEE 1364-2005 A.2.4 14.6 14.6.1
`timescale 1ns/1ns
module pathpulse_mintypmax_leaf(a, y);
  input a;
  output y;
  assign y = a;
  specify
    specparam PATHPULSE$ = (1:2:3);
    specparam PATHPULSE$a$y = (1:2:3, 4:5:6);
    (a => y) = 1;
  endspecify
endmodule
module b_A_2_4_pathpulse_mintypmax;
  wire y;
  pathpulse_mintypmax_leaf u(1'b1, y);
  initial #2 begin
    $display("y=%b", y);
    $finish(0);
  end
endmodule
