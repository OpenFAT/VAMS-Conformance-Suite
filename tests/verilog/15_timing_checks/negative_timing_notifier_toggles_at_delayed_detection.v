// IEEE 1364-2005 §15.5.3: "Because the reference and data signals are
// delayed internally, the detection of the timing violation is also delayed.
// Notifier regs in negative timing checks shall be toggled when the timing
// check detects a timing violation, which occurs when the delayed signals as
// measured by the adjusted timing check values are in violation, not when
// the undelayed signals at the model inputs as measured by the original
// timing check values are in violation." §15.5.1: "The delayed versions of
// the signals, whether implicit or explicit, shall be used in the $setup,
// $hold, $setuphold, ... timing checks; and these checks shall have their
// limits adjusted accordingly. This ensures the notifier shall be toggled at
// the proper moment." Example 2: a signal in two checks has one delayed
// signal, "used for both timing checks". "The delayed timing check signals
// are only actually delayed when negative limit values are present."
//
// The cell, both checks on one clk:
//   $setuphold(posedge clk, d, -2, 5, na): setup -2, window (ref+2, ref+5).
//     Its evaluation on the delayed signals with adjusted limits that are not
//     negative needs delayed clk at least 2 ns later than delayed d, so clk's
//     one delayed signal lags clk by 2 ns or more. d never changes: na
//     stays 0.
//   $setuphold(posedge clk, e, 3, 3, nb): window (ref-3, ref+3); it shares
//     clk's delayed signal. e is in no check with a negative limit.
//
// DERIVATION (t in ns):
//   t=99   e rises: in (97, 103) of the clk edge at 100, so nb's check is in
//          violation. Undelayed, with the original limits, that violation is
//          detected at the clk edge, t=100. Delayed, it is detected at the
//          later of delayed e and delayed clk, and delayed clk is no earlier
//          than t=102: §15.5.3 puts the toggle there, not at t=100.
//   t=101  nb has not toggled yet: "t=101 na=0 nb=0".
//   t=140  after every delayed event: nb went 0 -> 1 (Table 15-13):
//          "t=140 na=0 nb=1".
// gold: hand derivation, §15.5.1 and §15.5.3 (above)
//@ negative-timing
//! inherited IEEE 1364-2005 15.5.3 15.5.1
`timescale 1ns/1ps
module delayed_detection_cell(input clk, input d, input e);
  reg na, nb;
  initial #1 begin
    na = 1'b0;
    nb = 1'b0;
  end
  specify
    $setuphold(posedge clk, d, -2, 5, na);
    $setuphold(posedge clk, e, 3, 3, nb);
  endspecify
endmodule

module negative_timing_notifier_toggles_at_delayed_detection;
  reg clk = 0, d = 0, e = 0;
  delayed_detection_cell u(clk, d, e);
  initial begin
    #99 e = 1;
    #1 clk = 1;
    #1 $display("t=%0d na=%b nb=%b", $time, u.na, u.nb);
    #39 $display("t=%0d na=%b nb=%b", $time, u.na, u.nb);
    $finish(0);
  end
endmodule
