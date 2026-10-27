// IEEE 1364-2005 §17.2.9: "When addressing information is specified both in
// the system task and in the data file, the addresses in the data file shall
// be within the address range specified by the system task arguments;
// otherwise, an error message is issued, and the load operation is
// terminated." The load, not the simulation, ends; the clause leaves the
// run's exit status to the tool, and names neither the message's words nor
// its stream.
//
// HAND DERIVATION. mem[0:3], the task's range 0 to 1. The file:
//   @1 aa  -> mem[1] = aa
//   @0 bb  -> mem[0] = bb
//   @3 cc  -> 3 is outside 0..1: an error message, the load terminated
//   @0 dd  -> never read: mem[0] keeps bb
// mem[2] and mem[3] are never loaded and keep §4.2.2's x (%h prints xx).
//! inherited IEEE 1364-2005 17.2.9
//! exit any
//! diagnostic
//! stdout mem[0:3] = bb aa xx xx
module readmem_address_outside_task_range;
  reg [7:0] mem[0:3];
  initial begin
    $readmemh("readmem_address_outside_task_range.hex", mem, 0, 1);
    $display("mem[0:3] = %h %h %h %h", mem[0], mem[1], mem[2], mem[3]);
  end
endmodule
