// IEEE1364-2005 17.2.9: two valid words for a one-word range require
// a warning, unlike malformed punctuation following the completed range.
// §17.2.9 requires the warning in no set words or stream, so the run is
// judged by its value line(s) and `//! diagnostic`, not an exact transcript.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.2.9
//! stdout mem0=11
//! diagnostic
module audit_readmem_excess_legal_neighbor;
  reg [7:0] mem[0:0];
  initial begin
    $readmemh("readmem_excess_legal_neighbor.hex",mem,0,0);
    $display("mem0=%h",mem[0]);
  end
endmodule
