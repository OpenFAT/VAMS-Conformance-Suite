// IEEE 1364-2005 §15.8: "Both the $setuphold and $recrem timing checks can
// accept negative values when the negative timing check option is enabled."
// "A negative hold or setup time means the violation window is shifted to
// either before or after the reference edge." §15.5.2: timestamp_cond and
// timecheck_cond "immediately follow the notifier"; "timecheck_cond is
// associated with the delayed signal that transitions second". §15.2:
// "Reference events and data events shall only be detected by timing checks
// when their associated conditions are true."
//
// The cell: $setuphold(posedge clk, d, -2, 5, note, , enabled, ...): setup
// -2 and hold 5 give the window (ref + 2, ref + 5), §15.5.1 a) "exclusive of
// the end points". Two copies see the same clk and d; one has timecheck_cond
// 1, the other 0. Each condition is a constant, so the result does not hang
// on which delayed event it is associated with.
//
// DERIVATION (t in ns):
//   t=90   no violation yet: "before=0,0".
//   t=100  clk rises: the reference, window (102, 105).
//   t=103  d rises: in the window. The condition-1 copy violates and its
//          notifier goes 0 -> 1 (Table 15-13); the condition-0 copy detects
//          no event.
//   t=130  after every delayed event (the delays are the tool's, §15.5.1,
//          so the notifiers are read long after): "after=1,0".
// gold: hand derivation, §15.8, §15.5.2 and §15.2 (above)
//@ negative-timing
//! inherited IEEE 1364-2005 15.5.2 15.8
`timescale 1ns/1ps
module negative_enabled_cell(input clk, input d, input enabled);
  wire delayed_clk, delayed_d;
  reg note = 0;
  specify
    $setuphold(posedge clk, d, -2, 5, note, , enabled, delayed_clk, delayed_d);
  endspecify
endmodule

module negative_setuphold_timecheck_condition;
  reg clk = 0, d = 0;
  negative_enabled_cell enabled(clk, d, 1'b1), disabled(clk, d, 1'b0);
  initial begin
    #90 $display("before=%b,%b", enabled.note, disabled.note);
    #10 clk = 1;
    #3 d = 1;
    #27 $display("after=%b,%b", enabled.note, disabled.note);
    $finish(0);
  end
endmodule
