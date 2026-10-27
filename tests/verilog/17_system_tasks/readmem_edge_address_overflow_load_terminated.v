// IEEE 1364-2005 §17.2.9: a file address is "an at character (@) followed by
// a hexadecimal number"; "the addresses in the data file shall be within the
// address range specified by the system task arguments; otherwise, an error
// message is issued, and the load operation is terminated." The load, not
// the simulation, ends; the clause leaves the run's exit status to the tool.
//
// HAND DERIVATION. mem[0:1], the task's range 0 to 1. The file:
//   aa                   -> mem[0] = aa
//   @10000000000000000   -> 2**64, a hexadecimal number outside 0..1: an
//                           error message, the load terminated (64 bits
//                           would wrap it to 0, which is inside)
//   bb                   -> never read: mem[1] is not loaded
// mem[1] keeps §4.2.2's x (%h prints xx).
//! inherited IEEE 1364-2005 17.2.9
//! exit any
//! diagnostic
//! stdout mem[0:1] = aa xx
module readmem_edge_address_overflow_load_terminated;
  reg [7:0] mem[0:1];
  initial begin
    $readmemh("readmem_edge_address_overflow_load_terminated.hex", mem, 0, 1);
    $display("mem[0:1] = %h %h", mem[0], mem[1]);
  end
endmodule
