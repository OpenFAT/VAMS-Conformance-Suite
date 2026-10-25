//! inherited IEEE 1364-2005 4.11
//! reject a name is used before its declaration
// 1364-2005 has no general declare-before-use rule: it states one only for a
// specparam (§4.10.3, "shall be declared before it is referenced") and a
// named event (§9.7.3, "shall be declared explicitly before it is used").
// Where the standard is silent VerA does what the reference tool does:
// iverilog refuses `v`, a module-scope reg read by the initial block above
// its declaration (ivtest decl_before_use1), and so does VerA. (This fixture
// accepted the design until the conformance pass made the reference the
// tie-break.) A block's later local leaves an outer name in view instead
// (decl_before_use6). specification/Vague_Decisions.md VD-135.
module triage_forward_reference_reg;
  initial begin
    v = 1;
    if (v === 1) $display("PASSED"); else $display("FAILED %b", v);
  end

  reg v;
endmodule
