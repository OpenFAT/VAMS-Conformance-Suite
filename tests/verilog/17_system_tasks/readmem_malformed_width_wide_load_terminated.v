// IEEE1364-2005 17.2.9 p296 and1.2(a) p2: the same forbidden file
// prefix must produce an error regardless of memory-word width.
// Paired with the 8-bit test; changing destination width does not legalize
// an explicit length/base prefix. Exit convention and phrase are VerA-specific.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
//! warn the memory file has a malformed data word
module audit_readmem_malformed_width_wide_load_terminated;
  reg [15:0] mem[0:0];
  initial $readmemh("audit_readmem_invalid_width.txt",mem);
endmodule
