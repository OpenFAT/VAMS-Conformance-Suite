// IEEE 1364-2005 §13.3.2, p. 205: "For situations where it is desirable to
// specify a special set of configuration rules for a subsection of a design,
// it is possible to bind a particular instance directly to a configuration
// using the binding clause" ... "The design statement in lib1.foo:config
// shall specify the actual binding for the instance top.a1.foo, and the rules
// specified in the config shall determine the configuration of all other
// subinstances under top.a1.foo."
//
// The file holds two configs, and §13.4.4 names no rule for choosing the one
// that configures the design, so the transcript is made the same either way:
// only an instance whose parameter P is 1 prints, and only top sets it. A
// tool that also takes sub as a configuration of its own (its design
// statement makes gate a top-level module, §13.4.4) elaborates a top gate
// with P = 0, which prints nothing.
//
// top instantiates rtl as u. cfg binds top.u to the configuration sub, whose
// design statement names work.gate, so top.u is bound to gate, and P = 1
// reaches it. It prints its %m and %l (§13.6): "gate top.u work.gate". top
// finishes at t=1.
// gold: hand derivation, §13.3.2 and §13.6 (above)
//! inherited IEEE 1364-2005 13.3.2
`timescale 1ns/1ns
config sub;
  design work.gate;
endconfig
config cfg;
  design work.top;
  instance top.u use work.sub:config;
endconfig
module rtl;
  parameter P = 0;
  initial if (P) $display("rtl %m %l");
endmodule
module gate;
  parameter P = 0;
  initial if (P) $display("gate %m %l");
endmodule
module top;
  rtl #(1) u();
  initial #1 $finish(0);
endmodule
