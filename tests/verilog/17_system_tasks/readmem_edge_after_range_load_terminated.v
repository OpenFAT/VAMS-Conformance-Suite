// IEEE1364-2005 17.2.9, with3.5/3.5.1 and1.2(a) as applicable.
// 17.2.9 constrains the entire file content; reaching the last destination does not legalize punctuation.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
//! warn the memory file has a malformed data word
module audit_readmem_edge_after_range_load_terminated;
  reg [7:0] mem[0:0];
  initial $readmemh("audit_readmem_edge_after_range.txt",mem,0,0);
endmodule
