// IEEE 1364-2005 §15.5.2, p. 263: "The timestamp_cond and timecheck_cond
// arguments are associated with either the reference or data signals based
// on which delayed version of these signals occurs first. timestamp_cond is
// associated with the delayed signal that transitions first, while
// timecheck_cond is associated with the delayed signal that transitions
// second." timestamp_cond is the sixth argument of $setuphold.
//
// ORACLE: the same relation §15.5.2 states for timecheck_cond
// (setuphold_timecheck_condition.v), applied to the timestamp side: with
// timestamp_cond `en`, $setuphold(posedge clk, d, 4, 2, nc, en) checks as
// $setup(d &&& en, posedge clk, 4) (d, the setup window's timestamp,
// conditioned) and $hold(posedge clk &&& en, d, 2) (clk, the hold window's
// timestamp, conditioned). Notifiers `nc` and `nd` must toggle together.
//
// DERIVATION (t in ns; the stimulus of the neighbour):
//   t=1   "t=1 00".
//   t=12  clk rises; the timestamp d@10 had en 1, in (8, 12]: "t=12 11".
//   t=13  d falls; the timestamp clk@12 had en 1, in [12, 14): "t=13 00".
//   t=22  clk rises; d@20 had en 0, so it is no timestamp, and the last
//         one, d@13, is outside (18, 22]: none. t=23 d falls; clk@22 had
//         en 0, the last timestamp clk@12: none.
//   t=32  clk rises; d@30 had en 1 (en falls at 31), in (28, 32]:
//         "t=32 11". t=33 d falls; clk@32 had en 0: none.
//! inherited IEEE 1364-2005 15.5.1 15.5.2
//! neighbour setuphold_timecheck_condition.v
`timescale 1ns/1ns
module b_15_5_2_timestamp_cell(clk, d, en);
  input clk, d, en;
  reg nc, nd;
  initial #1 begin
    nc = 1'b0;
    nd = 1'b0;
  end
  initial $monitor("t=%0d %b%b", $time, nc, nd);
  specify
    $setuphold(posedge clk, d, 4, 2, nc, en);
    $setup(d &&& en, posedge clk, 4, nd);
    $hold(posedge clk &&& en, d, 2, nd);
  endspecify
endmodule

module b_15_5_2_setuphold_timestamp_condition;
  reg clk, d, en;
  b_15_5_2_timestamp_cell u(clk, d, en);
  initial begin
    clk = 0; d = 0; en = 1;
    #10 d = 1;
    #2 clk = 1;
    #1 d = 0;
    #2 clk = 0;
    #3 en = 0;
    #2 d = 1;
    #2 clk = 1;
    #1 d = 0;
    #2 clk = 0;
    #1 en = 1;
    #4 d = 1;
    #1 en = 0;
    #1 clk = 1;
    #1 d = 0;
    #5 $finish(0);
  end
endmodule
