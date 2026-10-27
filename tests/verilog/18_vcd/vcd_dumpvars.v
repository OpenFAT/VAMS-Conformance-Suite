// IEEE 1364-2005 §§18.1–18.2: four-state VCD artifact witness.
// The gold is compared through `//! expect vcd`, which sets aside every choice
// §18.2 leaves the writer (identifier codes, order within a time, `1 ns`).
//
// The tasks used here:
//   $dumpfile(name)       names the dump file.
//   $dumpvars(levels, scope)
//                         selects what to dump. `levels` 0 means the named
//                         scope and EVERY level below it.
//
// The file structure §18.2 requires, in order: a header section, the variable
// definitions, $enddefinitions, and then value-change sections keyed by
// #<time> records. Every variable gets a short printable-ASCII identifier code
// that stands in for its name in every later value change.
//
// HAND DERIVATION of vcd_dumpvars.expected.vcd:
//
//   Header. The directive is `timescale 1ns/1ns`, so the $timescale record
//   carries 1ns.
//
//   Definitions. Two variables are declared, in source order:
//     reg a          -> size 1, scalar, no range
//     reg [3:0] v    -> size 4, vector, range [3:0]
//   The gold's identifier codes run from `!` in declaration order: a gets
//   `!` and v gets `"`.
//
//   Value changes. All four steps of the initial block:
//     t=0  $dumpfile and $dumpvars run, then a <- 0 and v <- 0000. §18.2
//          starts dumping at the end of the current time unit (§18.1.3),
//          so the initial checkpoint observes 0 and 0000 and not the
//          X the variables held when $dumpvars was called.
//            #0
//            $dumpvars
//            0!
//            b0 "
//            $end
//          A vector value is written as `b<binary> <code>` with leading zeros
//          suppressed, so 4'b0000 is `b0` and not `b0000`.
//     t=1  a <- 1 only. v did not change, so v contributes nothing: §18.2
//          records CHANGES, not state.
//            #1
//            1!
//     t=2  v <- 4'b1010 only. Leading digit is 1, nothing to suppress.
//            #2
//            b1010 "
//     t=3  a <- 1'bx and v <- 4'bz01x in the same step. Both appear under one
//          #3 record (their order is the writer's).
//            #3
//            x!
//            bz01x "
//          `z01x` is written in full: suppression only removes a leading run
//          that repeats the leftmost character's extension, and here the
//          leftmost z is followed by 0, so all four characters stay.
//          These are the four-state encodings: scalar x is the single
//          character `x` prefixed to the code with NO separating space, while
//          a vector always has the `b` prefix and a space before the code.
//     The snapshot ends at #3. The old inference from $dumpflush to a
//     mandatory exact final line is withdrawn (VCD-ORACLE-001).
//
// gold: Icarus Verilog 13.0 agrees (through //! expect vcd's canonical compare)
//! inherited IEEE 1364-2005 18.1 ($dumpfile, $dumpvars)
//! inherited IEEE 1364-2005 18.2 (VCD format, identifier codes, value changes)
//! expect vcd d09_vcd.vcd == vcd_dumpvars.expected.vcd
`timescale 1ns/1ns
module d09_vcd;
  reg a;
  reg [3:0] v;
  initial begin
    $dumpfile("d09_vcd.vcd");
    $dumpvars(0, d09_vcd);
    a = 1'b0;
    v = 4'b0000;
    #1 a = 1'b1;
    #1 v = 4'b1010;
    #1 a = 1'bx;
       v = 4'bz01x;
       $finish(0);
  end
endmodule
