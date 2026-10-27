// IEEE 1364-2005 §17.2.9: "If the start address is greater than the finish
// address, then the address will be decremented between consecutive loads".
// "When addressing information is specified both in the system task and in
// the data file, the addresses in the data file shall be within the address
// range specified by the system task arguments; otherwise, an error message
// is issued, and the load operation is terminated." The load, not the
// simulation, ends; the clause leaves the run's exit status to the tool.
//
// HAND DERIVATION. mem[3:0], the task's range 1 down to 0. The file:
//   11     -> mem[1] = 11
//   22     -> mem[0] = 22
//   @2     -> 2 is outside 1..0, though inside the declared memory: an
//             error message, the load terminated
//   33     -> never read: mem[2] is not loaded
// mem[3] and mem[2] are never loaded and keep §4.2.2's x (%h prints xx).
//! inherited IEEE 1364-2005 17.2.9
//! exit any
//! diagnostic
//! stdout mem[3:0] = xx xx 11 22
module readmem_address_range_load_terminated;
  reg [7:0] mem[3:0];
  initial begin
    $readmemh("readmem_address_range_load_terminated.hex", mem, 1, 0);
    $display("mem[3:0] = %h %h %h %h", mem[3], mem[2], mem[1], mem[0]);
  end
endmodule
