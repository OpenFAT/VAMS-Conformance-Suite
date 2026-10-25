// IEEE 1364-2005 §17.2.9: when both the task and file specify addresses,
// an address outside the task's requested range is an error, ending the load
// (the load only: the run goes on, #65; see
// readmem_address_outside_task_range.v for the transcript).
// @2 is within the declared memory but outside requested indices 1..0.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
module audit_readmem_address_range_load_terminated;
  reg [7:0] mem[3:0];
  initial $readmemh("audit_readmem_restart.hex",mem,1,0);
endmodule
