//! event-budget 1000
//! inherited IEEE 1364-2005 9.9.2 11.4
//! reject E1100
//! reject keeps simulation time from advancing
// IEEE 1364-2005 §9.9.2: an always construct with no timing control "will
// cause a simulation deadlock" at time 0, and the clause's own example
// (`always areg = ~areg;`) is legal source that "creates a zero-delay
// infinite loop". VerA runs it, and the event budget ends the time step
// that never drains, by name (specification/Vague_Decisions.md VD-133).
// The default budget takes minutes in a Debug build, so this sets 1000.
// Legal neighbour: initial_and_always.v, whose always constructs each
// carry a timed statement.
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
