// The design cb_error_chk_error.c runs (VAMS-2023 12.31.4). No `//!`
// directive, so the suite does not collect it.
//
// At t=1, $readmemh loads cb_error_readmem.hex into mem[0:3]. The file's
// only address specification is @8, outside the task's range 0..3, so IEEE
// 1364-2005 17.2.9: "the addresses in the data file shall be within the
// address range specified by the system task arguments; otherwise, an error
// message is issued, and the load operation is terminated." $finish at t=2.
`timescale 1ns/1ns

module cb_error_readmem;
  reg [7:0] mem [0:3];

  initial begin
    #1 $readmemh("cb_error_readmem.hex", mem, 0, 3);
    #1 $finish(0);
  end
endmodule
