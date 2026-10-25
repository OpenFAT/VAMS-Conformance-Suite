// IEEE1364-2005 17.2.9, with3.5/3.5.1 and1.2(a) as applicable.
// A file address uses hexadecimal digits; g is not one.
// VerA reports the terminated load as warning W1157 and the simulation goes
// on, its exit status untouched, as iverilog does (oracle: iverilog -g2005
// prints this transcript; specification/Vague_Decisions.md VD-134).
//! inherited IEEE 1364-2005 17.2.9
//! warn W1157
//! warn the memory file has a malformed `@` address
module audit_readmem_edge_address_bad_digit_load_terminated;
  reg [7:0] mem[0:0];
  initial $readmemh("audit_readmem_edge_address_bad_digit.txt",mem,0,0);
endmodule
