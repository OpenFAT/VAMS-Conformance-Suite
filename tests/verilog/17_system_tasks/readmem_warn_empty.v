// IEEE1364-2005 17.2.9 p297: an address-free file with 0 data words
// differs from this inclusive 4-word load range and requires a warning.
// Exactly ONE load call: another call's warning cannot satisfy this oracle.
// Unfilled words retain aa; excess words cannot overwrite outside the range.
// §17.2.9 requires the warning in no set words or stream, so the run is
// judged by its value line(s) and `//! diagnostic`, not an exact transcript.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.2.9
//! stdout aa,aa,aa,aa
//! diagnostic
module audit_readmem_warn_empty;
  reg [7:0] mem[3:0];
  integer i;
  initial begin
    for(i=0;i<4;i=i+1) mem[i]=8'haa;
    $readmemh("audit_readmem_empty_comments.hex",mem,0,3);
    $display("%h,%h,%h,%h",mem[0],mem[1],mem[2],mem[3]);
  end
endmodule
