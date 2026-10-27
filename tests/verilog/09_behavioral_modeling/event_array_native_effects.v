// IEEE 1364-2005 §9.7.3: an event-array element in an event control is
// selected by its index, and an index may be a function call; §10.4.4 lets
// that function make blocking writes (only event triggers are barred, its
// invalid neighbour event_array_selector_trigger_rejected.v).
//
// §9.7.3 does not say when the index of an event control is evaluated, at
// suspension or at each occurrence, so the selector here returns its
// argument whatever the time, and the transcript prints only that it ran,
// not how often.
//
// DERIVATION: the waiter suspends on ev[choose(1)], which is ev[1], from
// before t=1 (#0, after every time-0 assignment). ev[0] at t=1 is another
// element: no wake. ev[1] at t=2 wakes it once: a = 1. choose ran at least
// once to select ev[1]: called = 1.
// gold: hand derivation, §9.7.3 and §10.4.4 (above)
//! inherited IEEE 1364-2005 9.7.3
//! inherited IEEE 1364-2005 10.4.4
// native-required
`timescale 1ns/1ns
module b_9_7_3_event_array_native_effects;
  event ev [0:1];
  integer calls, a;
  function automatic integer choose(input integer which);
    begin
      calls = calls + 1;
      choose = which;
    end
  endfunction
  initial begin
    a = 0; calls = 0;
    #1 -> ev[0];
    #1 -> ev[1];
    #1 $display("a=%0d called=%0d", a, calls > 0);
    $finish(0);
  end
  initial #0 forever @(ev[choose(1)]) a = a + 1;
endmodule
