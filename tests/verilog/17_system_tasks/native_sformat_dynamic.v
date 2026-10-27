// IEEE 1364-2005 §17.2.3, p. 290: the format "can be a reg variable whose
// content is interpreted as the format string". A native executable reads
// such a format when the task runs, so each argument meets its conversion
// only then.
//
//   fmt = "%s-%0d:%5.2f %% %c%m"; args "ab", 7, 1.5, 8'h41
//     %s "ab" -> ab; %0d 7 -> 7; %5.2f 1.5 -> " 1.50" (C's %5.2f, width 5);
//     %% -> %; %c 8'h41 -> A; %m (no argument) -> the module's name
//     -> "ab-7: 1.50 % Anative_sformat_dynamic"
// s holds that text padded on the left with zeros (§5.2.3.2), which is the
// value of the same string literal compared with s (§3.6): "match=1".
// (%s of s itself is not printed: §17.1.1.7's "leading zeros are never
// printed" does not say whether each leaves a blank. A format with too few
// or too many arguments is not used either: §17.2.3 lets a tool refuse that
// at compile time when it can tell, and leaves the text it writes open.)
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.2.3
// native-required
module native_sformat_dynamic;
  reg [8*48:1] s, fmt;
  initial begin
    fmt = "%s-%0d:%5.2f %% %c%m";
    $sformat(s, fmt, "ab", 7, 1.5, 8'h41);
    $display("match=%0d", s == "ab-7: 1.50 % Anative_sformat_dynamic");
    $finish(0);
  end
endmodule
