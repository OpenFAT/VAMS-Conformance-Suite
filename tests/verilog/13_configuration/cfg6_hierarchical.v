// IEEE 1364-2005 §13.5.5, p. 208: "config cfg5; design aLib.adder; default
// liblist gateLib aLib; instance adder.f1 liblist rtlLib; endconfig. To use
// this configuration cfg5 for the top.a2 instance of adder and take the full
// default aLib adder for the top.a1 instance, use the following config:
// config cfg6; design rtlLib.top; default liblist aLib rtlLib; instance
// top.a2 use work.cfg5:config ; endconfig. ... It is the design statement in
// config cfg5 that defines the exact binding for the top.a2 instance itself.
// The rest of cfg5 defines the rules to bind the descendants of top.a2. Notice
// the instance clause in cfg5 is relative to its own top-level module, adder."
// §13.3.2, p. 205: "The design statement in lib1.foo:config shall specify the
// actual binding for the instance top.a1.foo, and the rules specified in the
// config shall determine the configuration of all other subinstances".
//
// Both configs are in this file, which maps to work, so work.cfg5 is cfg5.
// §13.4.4 says a config's design statement names the top-level module, but
// not which of two configs on the command line is the root: cfg6 (top, with
// cfg5 serving top.a2) or cfg5 itself (adder at the top), or both. Under
// every reading cfg5 binds the descendants of one adder, relative to adder
// itself: its f1 by the instance clause to rtlLib.foo, its f2 by the default
// liblist to gateLib.foo (the §13.5 libraries in ex13_5/, each instance
// printing %m %l). So the run prints `...f1 rtlLib.foo` and `...f2
// gateLib.foo` (top.a2.f1, or adder.f1), and nothing more is forced.
// gold: hand derivation, §13.5.5 and §13.4.4 (above)
//@ libmap ex13_5/lib.map
//@ files ex13_5/top.v ex13_5/adder.v ex13_5/adder.vg
//! inherited IEEE 1364-2005 13.5.5 13.3.2 13.3.1.6 13.1.1
//! stdout f1 rtlLib.foo
//! stdout f2 gateLib.foo
`timescale 1ns/1ns
config cfg5;
    design aLib.adder;
    default liblist gateLib aLib;
    instance adder.f1 liblist rtlLib;
endconfig
config cfg6;
    design rtlLib.top;
    default liblist aLib rtlLib;
    instance top.a2 use work.cfg5:config ;
endconfig
