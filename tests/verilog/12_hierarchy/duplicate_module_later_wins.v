// gold: hand derivation, §13.2.1.1: the last same-named cell is written to work, so u is the second a and prints "later"; PASSED at t=1
//! inherited IEEE 1364-2005 13.2.1.1
// A later same-named module replaces the earlier with a warning; the instance
// binds the later one (pr1938138).
module a;
  initial $display("early");
endmodule

module triage_duplicate_module_later_wins;
  a u();

  initial #1 $display("PASSED");
endmodule

module a;
  initial $display("later");
endmodule
