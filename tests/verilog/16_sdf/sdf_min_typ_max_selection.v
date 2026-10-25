// Annotation replaces the original delay 1 with 11 (MAXIMUM of 3:7:11). Samples bracket t=31; ignoring
// annotation, or taking 7, fails the first sample. The rise comes at 20, after y's own x-to-0 has settled
// whichever delay timed it: §17.2.10 orders no time-0 annotation against a continuous assignment's first
// evaluation, and Table 14-3 times that x-to-0 at 11 once annotated.
//! inherited IEEE 1364-2005 16.6 17.2.10
`timescale 1ns/1ns
module sdf_cell(input a,output y);
  assign y=a;
  specify specparam delay_value=1; (a=>y)=delay_value; endspecify
endmodule
module sdf_min_typ_max_selection;
  reg a=0; wire y; integer fd; sdf_cell u(a,y);
  initial begin
    fd=$fopen("sdf_min_typ_max_selection.sdf","w");
    $fdisplay(fd,"(DELAYFILE");
    $fdisplay(fd," (SDFVERSION \"3.0\")");
    $fdisplay(fd," (TIMESCALE 1ns)");
    $fdisplay(fd," (CELL (CELLTYPE \"sdf_cell\") (INSTANCE) (DELAY (ABSOLUTE (IOPATH a y (3:7:11)))))");
    $fdisplay(fd,")");
    $fclose(fd);
    $sdf_annotate("sdf_min_typ_max_selection.sdf",u,,,"MAXIMUM");
    #20 a=1;
    #10 $display("before=%b",y);
    #2 $display("after=%b",y); $finish(0);
  end
endmodule
