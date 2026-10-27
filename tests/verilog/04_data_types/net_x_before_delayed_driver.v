// IEEE 1364-2005 §4.2.1, p. 23: "The default initialization value for a net
// shall be the value z. Nets with drivers shall assume the output value of
// their drivers." The clause does not say what a delayed driver outputs
// before its first update lands, so this reads only what it does pin:
//
// `assign #5 w = r;` (§6.1.3: the delay is "the time ... until the value of
// the left-hand side changes") evaluates r = 1 at t = 0 and schedules w = 1
// for t = 5. `wire #5 v = r;` is the net-declaration-assignment form (§6.1.2)
// of the same driver. At t = 1 neither update has landed, so neither net is
// 1 yet (whatever it reads before then): w1=0 v1=0. At t = 6 both read 1.
// `u` has no driver at all and reads the default z at both times.
//
// Neighbour: net_takes_driver_value.v, an undelayed driver.
//! inherited IEEE 1364-2005 4.2.1 6.1.3
`timescale 1ns/1ns
module b_4_2_1_net_x_before_delayed_driver;
  reg r;
  wire w, u;
  assign #5 w = r;
  wire #5 v = r;
  initial begin
    r = 1'b1;
    #1 $display("t=1 w1=%b v1=%b u=%b", w === 1'b1, v === 1'b1, u);
    #5 $display("t=6 w=%b v=%b u=%b", w, v, u);
    $finish(0);
  end
endmodule
