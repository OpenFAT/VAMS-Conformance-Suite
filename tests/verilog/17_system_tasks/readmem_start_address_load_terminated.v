// IEEE 1364-2005 17.2.9, printed297: file addresses must be inside the
// task-requested range. Start-only3 implies3..3, so @2 is outside even though
// it is inside the declared memory. This is an error, not a count warning.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
//! warn is outside the load range [3:3] the task gives
module audit_readmem_start_address_load_terminated;
  reg [7:0] mem[3:0];
  initial $readmemb("audit_readmem_formfeed_address.bin",mem,3);
endmodule
