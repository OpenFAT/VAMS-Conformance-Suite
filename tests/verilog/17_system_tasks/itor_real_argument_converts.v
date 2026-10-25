//! inherited IEEE 1364-2005 17.8
// §17.8's prototype `real $itor(int_val)` names an integer argument but no
// "shall" requires one. VerA converts a real argument to an integer first by
// §4.8.2 (rounded, halves away from zero), and one with no integer (an
// infinity or a NaN, whose integer is x) as 0; `$rtoi` of an integral value
// converts it to real first. This is iverilog -g2005's text (the oracle;
// ivtest itor_rtoi; specification/Vague_Decisions.md VD-128). This fixture
// was itor_real_argument_rejected until 2026-10-24.
//
//   $itor(10.4) = 10, $itor(-1.5) = -2, $itor(1.0/0.0) = 0, $rtoi(1'bx) = 0
module triage_itor_real_argument_converts;
  real r;

  initial begin
    r = $itor(10.4);
    $display("%g %g %g %0d", r, $itor(-1.5), $itor(1.0/0.0), $rtoi(1'bx));
  end
endmodule
