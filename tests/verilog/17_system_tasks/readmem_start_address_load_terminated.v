// IEEE 1364-2005 §17.2.9: "If the start address is specified in the task
// without the finish address, then loading shall start at the specified
// start address and shall continue upward toward the highest address in the
// memory." "When addressing information is specified both in the system task
// and in the data file, the addresses in the data file shall be within the
// address range specified by the system task arguments; otherwise, an error
// message is issued, and the load operation is terminated." The load, not
// the simulation, ends; the clause leaves the run's exit status to the tool.
//
// HAND DERIVATION. mem[3:0], the task's start 3, so its range is 3 up to the
// highest address, 3. audit_readmem_formfeed_address.bin, its items
// separated by formfeeds (white space, §17.2.9):
//   @3   -> inside 3..3
//   1    -> mem[3] = 8'b00000001
//   @2   -> 2 is outside 3..3, though inside the declared memory: an error
//           message, the load terminated
//   10   -> never read: mem[2] is not loaded
//   11   -> never read
// mem[2], mem[1] and mem[0] are never loaded and keep §4.2.2's x (%h prints
// xx).
//! inherited IEEE 1364-2005 17.2.9
//! exit any
//! diagnostic
//! stdout mem[3:0] = 01 xx xx xx
module readmem_start_address_load_terminated;
  reg [7:0] mem[3:0];
  initial begin
    $readmemb("audit_readmem_formfeed_address.bin", mem, 3);
    $display("mem[3:0] = %h %h %h %h", mem[3], mem[2], mem[1], mem[0]);
  end
endmodule
