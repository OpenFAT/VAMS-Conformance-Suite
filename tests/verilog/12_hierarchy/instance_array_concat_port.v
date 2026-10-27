// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 7.1.6 12.1.2
// §7.1.6's own example (ISP RAS test_07_01_06_3): an array of instances whose
// output port is connected to a concatenation `{bushigh, buslow}` as wide as
// the port times the element count, so "each instance shall get a part-select
// of the port expression ... starting with the right-hand index". The array
// and the four explicit instances are "equivalent", so the two columns pairs
// agree; the values are iverilog -g2005's.
module driver(in, out, en);
  input [3:0] in;
  output [3:0] out;
  input en;
  bufif0 ar[3:0](out, in, en);
endmodule

module busdriver(busin, bushigh, buslow, enh, enl);
  input [15:0] busin;
  output [7:0] bushigh, buslow;
  input enh, enl;
  driver busar3(busin[15:12], bushigh[7:4], enh);
  driver busar2(busin[11:8], bushigh[3:0], enh);
  driver busar1(busin[7:4], buslow[7:4], enl);
  driver busar0(busin[3:0], buslow[3:0], enl);
endmodule

module busdriver_equiv(busin, bushigh, buslow, enh, enl);
  input [15:0] busin;
  output [7:0] bushigh, buslow;
  input enh, enl;
  driver busar[3:0](.out({bushigh, buslow}), .in(busin), .en({enh, enh, enl, enl}));
endmodule

module instance_array_concat_port;
  reg [15:0] busin;
  reg enh, enl;
  integer i;
  wire [7:0] h1, l1, h2, l2;
  busdriver a(busin, h1, l1, enh, enl);
  busdriver_equiv b(busin, h2, l2, enh, enl);
  initial for (i = 0; i < 8; i = i + 1) begin
    busin = 16'h1234 * (i + 1) ^ 16'h0f0f;
    {enh, enl} = i;
    #1 $display("%h %h %h %h %h %b%b", busin, h1, l1, h2, l2, enh, enl);
  end
endmodule
