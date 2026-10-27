// IEEE 1364-2005 §17.2.9, printed p297: a sequential data count
// different from the start-to-finish range requires a warning, not refusal.
// Short input preserves unfilled aa bytes; excess input loads only the range.
// Explicit descending traversal reverses the same sequence of file words.
// §17.2.9 requires the warning in no set words or stream, so the run is
// judged by its value line(s) and `//! diagnostic`, not an exact transcript.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.2.9
//! stdout short-up=11,22,aa,aa
//! stdout short-down=aa,aa,22,11
//! stdout excess-up=11,22,33,44
//! stdout excess-down=44,33,22,11
//! diagnostic
module audit_readmem_count_warning;
  reg [7:0] mem[3:0];
  integer i;
  initial begin
    for(i=0;i<4;i=i+1) mem[i]=8'haa;
    $readmemh("audit_readmem_short.hex",mem,0,3);
    $display("short-up=%h,%h,%h,%h",mem[0],mem[1],mem[2],mem[3]);
    for(i=0;i<4;i=i+1) mem[i]=8'haa;
    $readmemh("audit_readmem_short.hex",mem,3,0);
    $display("short-down=%h,%h,%h,%h",mem[0],mem[1],mem[2],mem[3]);
    $readmemh("audit_readmem_excess.hex",mem,0,3);
    $display("excess-up=%h,%h,%h,%h",mem[0],mem[1],mem[2],mem[3]);
    $readmemh("audit_readmem_excess.hex",mem,3,0);
    $display("excess-down=%h,%h,%h,%h",mem[0],mem[1],mem[2],mem[3]);
  end
endmodule
