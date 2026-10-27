// IEEE1364-2005 §13.3.1.4: an unqualified cell selector may pair with
// `liblist`. Declaration acceptance only: the configuration binds the one
// module there is.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 13.3.1.4
config config_legal;
  design config_host;
  cell config_host liblist work;
endconfig
module config_host;
  initial begin $display("accepted"); $finish(0); end
endmodule
