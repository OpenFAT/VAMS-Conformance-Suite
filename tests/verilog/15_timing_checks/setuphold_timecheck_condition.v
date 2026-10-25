// IEEE 1364-2005 §15.5.2, p. 263: "This pair of $setup and $hold checks
// works together to provide the same check as a single $setuphold:
//     $setup (data, clk &&& cond1, tsetup, ntfr);
//     $hold (clk, data &&& cond1, thold, ntfr);
// ... The following $setuphold check is equivalent to the separate $setup
// and $hold checks shown above: $setuphold( clk, data, tsetup, thold, ntfr,
// , cond1);" timecheck_cond (argument 7) is "associated with the delayed
// signal that transitions second", the timecheck event.
//
// ORACLE: that stated equivalence, a metamorphic relation: notifier `na`
// (the $setuphold with timecheck_cond `en`) and `nb` (the clause's $setup
// and $hold pair) see the same stimulus and must toggle at the same times.
// With non-negative limits the delayed signals are the signals themselves
// (§15.5.1), so `dclk` is `clk` (setuphold_delayed_args.v).
//
// DERIVATION (t in ns; setup 4, hold 2; no reference and data event share a
// time step, where a $setuphold and a lone $setup differ):
//   t=1   both notifiers 0: "t=1 00".
//   t=10  d rises (en 1). t=12 clk rises: d@10 is in (8, 12] and en is 1 at
//         the timecheck: both violate, "t=12 11".
//   t=13  d falls, in [12, 14), en 1: both violate, "t=13 00".
//   t=18  en falls. t=20 d rises; t=22 clk rises: d@20 is in (18, 22] but
//         the timecheck (clk) sees en 0: no violation. t=23 d falls, in
//         [22, 24), the timecheck (d) sees en 0: none.
//   t=26  en rises. t=30 d rises; t=31 en falls; t=32 clk rises: en 0 at the
//         timecheck again: none; t=33 d falls: none.
//! inherited IEEE 1364-2005 15.5.1 15.5.2
//! neighbour setuphold_timestamp_condition.v
`timescale 1ns/1ns
module b_15_5_2_timecheck_cell(clk, d, en);
  input clk, d, en;
  reg na, nb;
  wire dclk;
  initial #1 begin
    na = 1'b0;
    nb = 1'b0;
  end
  initial $monitor("t=%0d %b%b", $time, na, nb);
  specify
    $setuphold(posedge clk, d, 4, 2, na, , en, dclk);
    $setup(d, posedge clk &&& en, 4, nb);
    $hold(posedge clk, d &&& en, 2, nb);
  endspecify
endmodule

module b_15_5_2_setuphold_timecheck_condition;
  reg clk, d, en;
  b_15_5_2_timecheck_cell u(clk, d, en);
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
