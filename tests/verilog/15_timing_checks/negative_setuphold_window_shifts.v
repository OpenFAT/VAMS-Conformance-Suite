// IEEE 1364-2005 §15.8: "Both the $setuphold and $recrem timing checks can
// accept negative values when the negative timing check option is enabled."
// "The setup and hold timing check values define a timing violation window
// with respect to the reference signal edge during which the data shall
// remain constant. Any change of the data during the specified window causes
// a timing violation." "A negative hold or setup time means the violation
// window is shifted to either before or after the reference edge." §15.5.1
// a): "A timing violation shall be triggered if the signal changes in the
// violation window, exclusive of the end points."
//
// Two cells, each on its own clk and d, each notifier starting at 0 at t=1:
//   late:  $setuphold(posedge clk, d, -2, 5, n): the window (ref+2, ref+5),
//          after the edge.
//   early: $setuphold(posedge clk, d, 5, -2, n): the window (ref-5, ref-2),
//          before the edge.
// Each violation toggles the notifier (Table 15-13). The delays a tool gives
// its delayed signals are its own (§15.5.1), so each notifier is read 40 ns
// after the edge, long after them.
//
// DERIVATION, late (t in ns; reference edges at 100, 200, ..., 500):
//   d at 101: before (102, 105): none.       t=140 n=0
//   d at 202: (202, 205)'s open start: none. t=240 n=0
//   d at 303: in (302, 305): VIOLATION.      t=340 n=1
//   d at 405: (402, 405)'s open end: none.   t=440 n=1
//   d at 506: after (502, 505): none.        t=540 n=1
// DERIVATION, early (reference edges at 1100, ..., 1500):
//   d at 1099: after (1095, 1098): none.         t=1140 n=0
//   d at 1198: (1195, 1198)'s open end: none.    t=1240 n=0
//   d at 1297: in (1295, 1298): VIOLATION.       t=1340 n=1
//   d at 1395: (1395, 1398)'s open start: none.  t=1440 n=1
//   d at 1494: before (1495, 1498): none.        t=1540 n=1
// A tool that read either negative limit as 0 would see violations at 101,
// 202, 1099 and 1198 as well.
// gold: hand derivation, §15.8 and §15.5.1 a) (above)
//@ negative-timing
//! inherited IEEE 1364-2005 15.8 15.5.1
`timescale 1ns/1ps
module negative_window_late(input clk, input d);
  reg n;
  initial #1 n = 1'b0;
  specify
    $setuphold(posedge clk, d, -2, 5, n);
  endspecify
endmodule

module negative_window_early(input clk, input d);
  reg n;
  initial #1 n = 1'b0;
  specify
    $setuphold(posedge clk, d, 5, -2, n);
  endspecify
endmodule

module negative_setuphold_window_shifts;
  reg lclk = 0, ld = 0, eclk = 0, ed = 0;
  negative_window_late late(lclk, ld);
  negative_window_early early(eclk, ed);
  // One reference edge at `edge_at`, d toggled at `edge_at + offset` (late)
  // or `edge_at - lead` (early; non-negative, as `$time` is unsigned), and
  // the notifier read at `edge_at + 40`; the clock falls at `edge_at + 50`.
  task late_cycle(input integer edge_at, input integer offset);
    begin
      #(edge_at - $time) lclk = 1;
      #(offset) ld = ~ld;
      #(40 - offset) $display("late t=%0d n=%b", $time, late.n);
      #10 lclk = 0;
    end
  endtask
  task early_cycle(input integer edge_at, input integer lead);
    begin
      #(edge_at - lead - $time) ed = ~ed;
      #(lead) eclk = 1;
      #40 $display("early t=%0d n=%b", $time, early.n);
      #10 eclk = 0;
    end
  endtask
  initial begin
    late_cycle(100, 1);
    late_cycle(200, 2);
    late_cycle(300, 3);
    late_cycle(400, 5);
    late_cycle(500, 6);
    early_cycle(1100, 1);
    early_cycle(1200, 2);
    early_cycle(1300, 3);
    early_cycle(1400, 5);
    early_cycle(1500, 6);
    $finish(0);
  end
endmodule
