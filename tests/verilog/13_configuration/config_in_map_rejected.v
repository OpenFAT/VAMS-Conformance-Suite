// IEEE 1364-2005 §13.2.2, p. 202: "The syntax of a lib.map file is limited to
// library specifications, include statements, and standard Verilog comment
// syntax." A config declaration is none of the three, so a map holding one
// breaks the clause's limit.
//
// libmap/bad/config_in_map.map declares a library and then a config. Legal
// neighbours: include_map.v (a map of an include statement and a
// comment) and config_design_select.v (the same config in source text).
//@ libmap libmap/bad/config_in_map.map
//! inherited IEEE 1364-2005 13.2.2
//! reject E0244
//! reject found `config`
//! neighbour config_design_select.v
//! neighbour include_map.v
module top;
endmodule
