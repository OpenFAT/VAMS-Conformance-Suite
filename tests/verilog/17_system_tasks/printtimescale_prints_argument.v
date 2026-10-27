// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.3.1
// §17.3.1's format is "Time scale of (module_name)", and the clause does not
// say whether the name is as written or the full hierarchical one. VerA
// prints the full hierarchical name, as iverilog does (oracle: iverilog
// -g2005, ivtest pr1701855, which prints `top.dut` for `$printtimescale(dut)`).
`timescale 1ns/1ns
module triage_printtimescale_prints_argument;
  dut_triage d();

  initial begin
    $printtimescale(d);
    $finish(0);
  end
endmodule

`timescale 1ns/1ns
module dut_triage;
endmodule
