// gold: Icarus Verilog 13.0 agrees
//@ std 1364-2005
//! inherited IEEE 1364-2005 19.3.1
//! warn W0151
// IEEE 1800-2017 §22.5.1 adds `" (a string whose formals are still
// substituted), `\`" (a \" inside it) and `` (a token join) to macro text.
// IEEE 1364-2005 Syntax 19-3 has none of them. VerA reads them under every
// standard (user ruling) and, under --std=1364-*, says the source is not
// portable (W0151). Oracle: the clause's own examples and their expansions,
// `msg(left side,right side) -> "left side: \"right side\"" and
// `append(clock) -> clock_master (iverilog -E agrees).
`define msg(x,y) `"x: `\`"y`\`"`"
`define append(f) f``_master
module macro_text_1800_forms_warn;
  integer clock_master;
  initial begin
    clock_master = 5;
    $display(`msg(left side,right side));
    $display("%0d", `append(clock));
  end
endmodule
