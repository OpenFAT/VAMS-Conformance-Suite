// IEEE 1364-2005 §4.2.1, p. 23: "The default initialization value for a net
// shall be the value z. Nets with drivers shall assume the output value of
// their drivers." `w` and `v` have a driver from the start, so they read what
// it outputs, and a delayed driver outputs nothing known until its first
// update lands: §8.5 Figure 8-1 draws q and qb, behind `buf #3` and `not #5`,
// as unknown until simulation times 3 and 5. Only a net with no driver, `u`,
// reads the default z (specification/Vague_Decisions.md VD-126). (This
// fixture read z for the driven nets until G8;
// iverilog, the reference tool, prints these lines.)
//
// `assign #5 w = r;` (§6.1.3: the delay is "the time ... until the value of
// the left-hand side changes") evaluates r = 1 at t = 0 and schedules w = 1
// for t = 5. `wire #5 v = r;` is the net-declaration-assignment form (§6.1.2)
// of the same driver. At t = 1 neither update has landed: both read x. At
// t = 6 both read 1.
//
// Neighbour: net_takes_driver_value.v, an undelayed driver.
//! inherited IEEE 1364-2005 4.2.1 6.1.3 8.5
`timescale 1ns/1ns
module b_4_2_1_net_x_before_delayed_driver;
  reg r;
  wire w, u;
  assign #5 w = r;
  wire #5 v = r;
  initial begin
    r = 1'b1;
    #1 $display("t=1 w=%b v=%b u=%b", w, v, u);
    #5 $display("t=6 w=%b v=%b u=%b", w, v, u);
    $finish(0);
  end
endmodule
