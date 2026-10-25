//! inherited IEEE 1364-2005 17.1.3 17.4.1
// A $monitor change in the time step where $finish executes is printed:
// §17.4.1 says only that $finish makes the simulator exit, and VerA, as
// iverilog does (oracle: iverilog -g2005 prints these lines; ivtest
// monitor4, pr243), ends the run once that time step has drained, so its
// end-of-step monitor line (§17.1.3) is written.
module triage_monitor_change_at_finish_printed;
  integer a;

  initial begin
    a = 0;
    $monitor("m %0d", a);
    #1 a = 1;
    $finish(0);
  end
endmodule
