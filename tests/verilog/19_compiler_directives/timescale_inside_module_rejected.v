//! inherited IEEE 1364-2005 19.8
//! reject a `timescale directive is written outside a module definition
// §19.8 gives a `timescale to "all modules that follow this directive until
// another `timescale compiler directive is read" and has no "shall" on where
// the directive is written. Where the standard is silent VerA does what the
// reference tool does: iverilog refuses a `timescale inside a module
// definition (ivtest no_timescale_in_module), and so does VerA. (This fixture
// accepted it until the conformance pass made the reference the tie-break;
// specification/Vague_Decisions.md VD-136.)
`timescale 1ns/1ps
module triage_timescale_inside_module;
`timescale 1us/1ns
  initial $display("PASSED");
endmodule
