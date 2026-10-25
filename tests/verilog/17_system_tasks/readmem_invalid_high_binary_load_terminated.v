// IEEE1364-2005 17.2.9 p296 and1.2(a) p2: invalid radix digits
// require an error even beyond the destination word's retained low bits.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
//! warn the memory file has a malformed data word
module audit_readmem_invalid_high_binary_load_terminated;
  reg [7:0] mem[0:0];
  initial $readmemb("audit_readmem_invalid_high_binary.txt",mem);
endmodule
