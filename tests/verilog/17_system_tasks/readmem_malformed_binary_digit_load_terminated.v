// IEEE1364-2005 17.2.9 p296: Each readmemb data number shall be binary; digit2 is not binary.
// IEEE1.2(a) p2 requires an error when input violates a shall requirement.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
//! warn the memory file has a malformed data word
module audit_readmem_malformed_binary_digit_load_terminated;
  reg [7:0] mem[0:0];
  initial $readmemb("audit_readmem_invalid_binary_digit.txt",mem);
endmodule
