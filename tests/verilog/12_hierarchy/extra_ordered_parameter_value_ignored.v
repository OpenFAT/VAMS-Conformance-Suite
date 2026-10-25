// VerA ignores the values past the last parameter with warning W1161, as
// iverilog does (oracle: iverilog -g2005 prints this transcript;
// specification/Vague_Decisions.md VD-139): the clause says what the
// list's order follows, not what a longer list means.
//! inherited IEEE 1364-2005 12.2.2.1
//! warn W1161
//! warn the extra ones are ignored
// An ordered parameter list follows the declaration order; module sub has no
// parameter left to take a value, so #(1, 2, 3) has nothing to set (param_test3).
module triage_extra_ordered_parameter_value_ignored;
  wire a;

  sub #(1, 2, 3) u(a);
endmodule

module sub(a);
  input a;
endmodule
