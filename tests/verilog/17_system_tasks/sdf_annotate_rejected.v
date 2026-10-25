// IEEE 1364-2005 §17.2.10: "The $sdf_annotate system task reads timing data
// from an SDF file into a specified region of the design." The clause names
// no behaviour for a file that is not there. VerA stops the run (E1102)
// rather than going on: carrying on past the call would simulate a design
// whose timing the SDF file was meant to set. No file of this name exists
// beside the source or in the working directory.
//
// Legal neighbours: 16_sdf/*.v write their SDF file first, then annotate it.
//! inherited IEEE 1364-2005 17.2.10 16 16.1
//! reject E1102
module sdf_annotate_rejected;
  reg a;
  initial begin
    $sdf_annotate("sdf_annotate_rejected.sdf");
    a = 1'b0;
  end
endmodule
