// IEEE 1364-2005 §12.2.2.1, p. 170: "The order of the assignments in the module
// instance parameter value assignment by ordered list shall follow the order
// of declaration of the parameters within the module." p. 171: "Local
// parameters cannot be overridden; therefore, they are not considered part of
// the ordered list for parameter value assignment."
//
// my_mem's ordered list is (addr_width, data_width): two entries, the
// localparam mem_size not among them. #(12, 16, 8) supplies a third value that
// no parameter follows. Legal neighbour: parameter_assignment_forms.v
// (my_mem #(12, 16)).
// VerA ignores the values past the last parameter with warning W1161, as
// iverilog does (oracle: iverilog -g2005 prints this transcript;
// specification/Vague_Decisions.md VD-139): the clause says what the
// list's order follows, not what a longer list means.
//! inherited IEEE 1364-2005 12.2.2.1
//! warn W1161
//! warn the extra ones are ignored
//! neighbour parameter_assignment_forms.v
module my_mem;
  parameter addr_width = 16;
  localparam mem_size = 1 << addr_width;
  parameter data_width = 8;
  initial $display("%0d %0d %0d", addr_width, mem_size, data_width);
endmodule
module b_12_2_2_1_extra_ordered_value_ignored;
  my_mem #(12, 16, 8) m();
endmodule
