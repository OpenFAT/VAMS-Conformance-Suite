// IEEE 1364-2005 §17.6.5, Table 17-15: "2 Mean interarrival time", "4
// Shortest wait time ever", "6 Average wait time in the queue". q_stat_value
// is an integer and the clause defines none of them further. VerA computes
// what iverilog does (specification/Vague_Decisions.md VD-052; oracle:
// iverilog -g2005, ivtest queue_stat, whose transcript this file matches):
// each mean truncates, code 6 averages the wait of every job so far, those
// that left and those still queued, and a statistic with no population yet
// leaves q_stat_value as it was (iverilog writes x there; v is x before the
// call, so the line below reads the same either way).
//
// HAND DERIVATION. Queue 1, FIFO, max_length 5, times in ns (1 ns / 1 ns):
//   t=0 add job 1; code 4 before any job left: no value, v stays x
//   t=2 add job 2, t=5 add job 3
//     interarrivals 2 - 0 = 2 and 5 - 2 = 3: mean 2.5 -> 2
//   t=6 remove: job 1 leaves after 6 - 0 = 6
//   t=9 remove: job 2 leaves after 9 - 2 = 7
//     waits 6 and 7, and job 3 queued for 9 - 5 = 4: mean 17 / 3 -> 5
//
// No rejection fixture: the calls are the legal four-argument form, and a
// code outside Table 17-15 is q_exam_code_rejected.v.
//! inherited IEEE 1364-2005 17.6.5
`timescale 1 ns / 1 ns
module b_17_6_5_q_exam_means;
  integer status, v, job, info;
  initial begin
    $q_initialize(1, 1, 5, status);
    $q_add(1, 1, 0, status);
    v = 32'bx;
    $q_exam(1, 4, v, status);
    $display("shortest=%0d", v);
    #2 $q_add(1, 2, 0, status);
    #3 $q_add(1, 3, 0, status);
    #1 $q_remove(1, job, info, status);
    #3 $q_remove(1, job, info, status);
    $q_exam(1, 2, v, status);
    $display("interarrival=%0d status=%0d", v, status);
    $q_exam(1, 6, v, status);
    $display("wait=%0d status=%0d", v, status);
    $finish(0);
  end
endmodule
