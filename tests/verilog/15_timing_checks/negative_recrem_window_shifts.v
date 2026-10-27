// IEEE 1364-2005 §15.8: "Both the $setuphold and $recrem timing checks can
// accept negative values when the negative timing check option is enabled.
// The behavior of these two timing checks is identical with respect to
// negative values. The descriptions in this subclause are for the $setuphold
// timing check, but apply equally to the $recrem timing check." "A negative
// hold or setup time means the violation window is shifted to either before
// or after the reference edge." §15.2.6: $recrem(posedge clear, posedge clk,
// tREC, tREM) is $removal(..., tREM) and $recovery(..., tREC): the removal
// limit bounds a data event before the reference event, the recovery limit
// one after it, as setup and hold do. "When either the removal limit or the
// recovery limit is negative, ... removal_limit + recovery_limit >
// (simulation unit of precision)": 3 ns > 1 ps here. §15.5.1 a): the window
// is "exclusive of the end points".
//
// Two cells, each on its own clr and clk, each notifier starting at 0 at t=1:
//   late:  $recrem(posedge clr, posedge clk, 5, -2, n): tREC 5, tREM -2, the
//          window (ref+2, ref+5), after the clr edge.
//   early: $recrem(posedge clr, posedge clk, -2, 5, n): tREC -2, tREM 5, the
//          window (ref-5, ref-2), before it.
// Each violation toggles the notifier (Table 15-13). The delays a tool gives
// its delayed signals are its own (§15.5.1), so each notifier is read 40 ns
// after the clr edge, long after them. clk falls between its rises; a
// negedge is no data event of `posedge clk`.
//
// DERIVATION, late (t in ns; clr rises at 100, 200, ..., 500):
//   clk rises at 101: before (102, 105): none.       t=140 n=0
//   clk rises at 202: (202, 205)'s open start: none. t=240 n=0
//   clk rises at 303: in (302, 305): VIOLATION.      t=340 n=1
//   clk rises at 405: (402, 405)'s open end: none.   t=440 n=1
//   clk rises at 506: after (502, 505): none.        t=540 n=1
// DERIVATION, early (clr rises at 1100, ..., 1500):
//   clk rises at 1099: after (1095, 1098): none.         t=1140 n=0
//   clk rises at 1198: (1195, 1198)'s open end: none.    t=1240 n=0
//   clk rises at 1297: in (1295, 1298): VIOLATION.       t=1340 n=1
//   clk rises at 1395: (1395, 1398)'s open start: none.  t=1440 n=1
//   clk rises at 1494: before (1495, 1498): none.        t=1540 n=1
// A tool that read either negative limit as 0 would see violations at 101,
// 202, 1099 and 1198 as well.
// gold: hand derivation, §15.8, §15.2.6 and §15.5.1 a) (above)
//@ negative-timing
//! inherited IEEE 1364-2005 15.8 15.2.6
`timescale 1ns/1ps
module negative_recrem_late(input clr, input clk);
  reg n;
  initial #1 n = 1'b0;
  specify
    $recrem(posedge clr, posedge clk, 5, -2, n);
  endspecify
endmodule

module negative_recrem_early(input clr, input clk);
  reg n;
  initial #1 n = 1'b0;
  specify
    $recrem(posedge clr, posedge clk, -2, 5, n);
  endspecify
endmodule

module negative_recrem_window_shifts;
  reg lclr = 0, lclk = 0, eclr = 0, eclk = 0;
  negative_recrem_late late(lclr, lclk);
  negative_recrem_early early(eclr, eclk);
  // clr rises at `edge_at`, clk at `edge_at + offset` (late) or `edge_at -
  // lead` (early; non-negative, as `$time` is unsigned); the notifier is read
  // at `edge_at + 40`, and both fall at `edge_at + 50`.
  task late_cycle(input integer edge_at, input integer offset);
    begin
      #(edge_at - $time) lclr = 1;
      #(offset) lclk = 1;
      #(40 - offset) $display("late t=%0d n=%b", $time, late.n);
      #10 begin lclr = 0; lclk = 0; end
    end
  endtask
  task early_cycle(input integer edge_at, input integer lead);
    begin
      #(edge_at - lead - $time) eclk = 1;
      #(lead) eclr = 1;
      #40 $display("early t=%0d n=%b", $time, early.n);
      #10 begin eclr = 0; eclk = 0; end
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
