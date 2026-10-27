// IEEE 1364-2005 §9.6: "while  Executes a statement until an expression
// becomes false." An untimed loop that ends is legal however long it runs,
// so a tool that bounds the work of one time step (the `event-budget` line
// below sets such a bound where a tool has one) must still run this one to
// its end: 900 passes and two process events fit in a budget of 1000.
//
// DERIVATION: the loop ends with n = 900 at time 0 and the run goes on to
// time 5.
//! event-budget 1000
//! inherited IEEE 1364-2005 9.6
module b_9_6_untimed_loop_under_budget;
  integer n;
  initial begin
    n = 0;
    while (n < 900) n = n + 1;
    $display("%0d", n);
  end
  initial #5 $display("t=%0t n=%0d", $time, n);
endmodule
