//! inherited IEEE 1364-2005 9.9.2 11.4
//! reject E1100
//! reject has no timing control
// IEEE 1364-2005 §9.9.2: an always construct with no timing control "will
// cause a simulation deadlock" at time 0, when every process starts. The
// clause names a run-time outcome, not an error; VerA refuses such a
// construct before any process runs, as iverilog does ("always process does
// not have any delay", ivtest always3.1.1B), whichever process would have
// run first. Legal neighbour: initial_and_always.v, whose always constructs
// each carry a timed statement.
//! neighbour initial_and_always.v
module triage_zero_delay_always_rejected;
  reg [3:0] value1;

  initial begin
    if (value1 != 4'b1)
      $display("FAILED");
    else
      $display("PASSED");
    $finish(0);
  end

  always value1 = 1'b1 && 1'b1;
endmodule
