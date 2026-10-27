// IEEE 1364-2005 §§5.2.2 and 9.7.3: an event array is selected by its
// integer address, including a wide sign-extended negative address. An
// address outside the bounds, or with an x bit, names no element (§5.2.2:
// "the address bounds given in the declaration ... determine the effect of
// the address expression"), so a trigger through it wakes nothing, even when
// its low 64 bits read -2. No invalid form is invented for a legal wide
// index; the real-index rejection is native_wide_event_real_index_rejected.v.
//
// §9.7.3 does not say when the index of an event control is evaluated, so
// the waiter's address, selected = -2, is set before it suspends (#0) and
// never changes.
//   t=1 ready[-1]: another element.     t=2 ready[selected]: wake 1.
//   t=3 address 2**64 - 2: out of range. t=4 x high bits: no element.
//   t=5 ready[-2]: wake 2.              t=6 "total 2".
// gold: hand derivation, §5.2.2 and §9.7.3 (above)
//! inherited IEEE 1364-2005 5.2.2 9.7.3
// native-required
module native_wide_event_indices;
  event ready[-1:-2];
  reg signed [129:0] selected;
  integer wakes;
  initial begin
    wakes = 0; selected = -130'sd2;
    #1 -> ready[-130'sd1];
    #1 -> ready[selected];
    #1 -> ready[(130'sd1 << 64) - 130'sd2];
    #1 -> ready[{66'bx, 64'hfffffffffffffffe}];
    #1 -> ready[-130'sd2];
    #1 $display("total %0d", wakes);
    $finish(0);
  end
  initial #0 forever @(ready[selected]) begin
    wakes = wakes + 1;
    $display("wake %0d %0d", wakes, $time);
  end
endmodule
