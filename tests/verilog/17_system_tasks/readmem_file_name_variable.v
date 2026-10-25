//! inherited IEEE 1364-2005 17.2.9 17.2.1
// Syntax 17-7 writes $readmem's file name as `" file_name "`, the placeholder
// Syntax 17-4 uses for $fopen, which §17.2.1 defines: "file_name is a
// character string or is a reg containing a character string that names the
// file to be opened". So a string parameter (iverilog's pr690) and a reg
// holding the characters (pr704) name the file as a literal does; this
// fixture read the parameter form as refused until the audit's correction.
//
// HAND DERIVATION: readmem_file_name_variable.dat holds 01 and 10 (binary).
// Each load writes mem[0] = 1, mem[1] = 2; the reg form loads from address 1
// (start 1), so m2[1] = 1 and m2[0] stays x.
module triage_readmem_file_name_variable;
  parameter MemFile = "readmem_file_name_variable.dat";
  reg [8*40:1] name;
  reg [7:0] mem [0:1];
  reg [7:0] m2 [0:2];

  initial begin
    $readmemb(MemFile, mem, 0);
    $display("%0d %0d", mem[0], mem[1]);
    name = "readmem_file_name_variable.dat";
    $readmemb(name, m2, 1);
    $display("%0d %0d %0d", m2[0], m2[1], m2[2]);
  end
endmodule
