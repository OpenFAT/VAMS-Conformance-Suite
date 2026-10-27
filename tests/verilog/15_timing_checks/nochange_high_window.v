// A change strictly inside the high window violates; a change after it or exactly on its trailing endpoint does not.
// gold: hand derivation, §15.3.6: d@12 is in (10, 20) and toggles note; d@22 is outside and d@40 is the open end of (30, 40)
//! inherited IEEE 1364-2005 15.3.6
`timescale 1ns/1ns
module nochange_cell(input clk,input d);
  reg note=0;
  specify $nochange(posedge clk,d,0,0,note); endspecify
endmodule
module nochange_high_window;
  reg clk=0,d=0; nochange_cell u(clk,d);
  initial begin
    #10 clk=1; #2 d=1; #2 $display("inside=%b",u.note);
    #6 clk=0; #2 d=0; #2 $display("outside=%b",u.note);
    #6 clk=1; #10 begin clk=0; d=1; end
    #2 $display("endpoint=%b",u.note); $finish(0);
  end
endmodule
