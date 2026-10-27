// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.3.1
// IEEE 1364-2005 §17.3.1: "When an argument is specified, $printtimescale
// displays the time unit and precision of the module passed to it." The
// clause does not say what an argument that names an object inside a module
// does; VerA does what iverilog does (oracle: iverilog -g2005, ivtest
// pr1701855b, whose transcript this file matches): it reports the time scale
// of the module the object is declared in, under the object's full
// hierarchical name. .P is a parameter of a 1 ns / 1 ns module.
`timescale 1ns/1ns
module triage_printtimescale_names_parameter;
  parameter P = 2;

  initial $printtimescale(triage_printtimescale_names_parameter.P);
endmodule
