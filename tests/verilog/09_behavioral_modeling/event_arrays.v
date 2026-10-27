// IEEE 1364-2005 §9.7.3 / AMS §5.10.4: events hold no data. Changing an
// event-array index does not cause an event. Each selected element is a
// distinct event, including hierarchical, task and block-local references.
//
// DERIVATION: a[0] occurs at t=1 and 3; a[i] at t=4, after i becomes 1 at
// t=2, is a[1]. The waiter on b[i] sees i change at t=2, which is no
// occurrence (§9.7.3), and no b element is ever triggered, so moved stays 0
// whether the index is read at suspension or followed (§9.7.3 does not say
// which; a waiter that a later trigger could tell apart would not be
// forced). At t=5 matrix[-2][4], child.ev[5] and scalar
// each occur once. Block and task events each occur at t=2. All waiters arm
// at t=0 before their triggers; observing at t=6 avoids active-region races.
// Invalid neighbors: b_9_7_3_event_array_*_rejected.v.
// gold: Verilator 5.052 agrees
//! inherited IEEE 1364-2005 9.7.3
//! lrm 5.10.4
//! lrm 5.10.4:1002
//! lrm 5.10.4:2
// native-required
`timescale 1ns/1ns
module event_array_child;
  parameter LO = 5, HI = 6;
  event ev [HI:LO];
  integer hits;
  initial hits = 0;
  always @(ev[LO]) hits = hits + 1;
endmodule
module b_9_7_3_event_arrays;
  event a [0:1], b [0:1], matrix [-2:-1][5:4], scalar;
  integer i, c0, c1, moved, matrix_hits, scalar_hits, task_hits;
  event_array_child child();
  task rendezvous;
    event local_ev [3:2];
    begin
      fork
        begin @(local_ev[2]); task_hits = task_hits + 1; end
        begin #2 -> local_ev[2]; end
      join
    end
  endtask
  initial begin
    i = 0; c0 = 0; c1 = 0; moved = 0;
    matrix_hits = 0; scalar_hits = 0; task_hits = 0;
    #1 -> a[0];
    #1 i = 1;
    #1 begin $display("index change: moved=%0d", moved); -> a[0]; end
    #1 -> a[i];
    #1 begin -> matrix[-2][4]; -> child.ev[5]; -> scalar; end
    #1 begin
      $display("events: c0=%0d c1=%0d moved=%0d matrix=%0d child=%0d scalar=%0d block=%0d task=%0d", c0, c1, moved, matrix_hits, child.hits, scalar_hits, local_block.hits, task_hits);
      $finish(0);
    end
  end
  always @(a[0]) c0 = c0 + 1;
  always @(a[1]) c1 = c1 + 1;
  always @(b[i]) moved = moved + 1;
  always @(matrix[-2][4]) matrix_hits = matrix_hits + 1;
  always @(scalar) scalar_hits = scalar_hits + 1;
  initial rendezvous();
  initial begin : local_block
    event local_ev [1:-1];
    integer hits;
    hits = 0;
    fork
      begin @(local_ev[-1]); hits = hits + 1; end
      begin #2 -> local_ev[-1]; end
    join
  end
endmodule
