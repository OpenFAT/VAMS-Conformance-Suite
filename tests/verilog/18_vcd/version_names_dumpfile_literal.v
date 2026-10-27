// IEEE 1364-2005 §18.2.3.8, p. 335: "The $version section indicates which
// version of the VCD writer was used to produce the VCD file and the $dumpfile
// system task used to create the file." Syntax 18-16:
//   vcd_declaration_version ::= $version version_text system_task $end
// §18.2.3.2, p. 332: "The $date section indicates the date on which the VCD
// file was generated." Syntax 18-10: `$date date_text $end`.
// §18.2.1, p. 330: "The VCD file starts with header information giving the
// date, the version number of the simulator used for the simulation, and the
// timescale used. Next, the file contains definitions of the scope and type of
// variables being dumped, followed by the actual value changes at each
// simulation time increment."
// §18.1.6, p. 328: "The $dumpflush task can be used to empty the VCD file
// buffer of the operating system to ensure all the data in that buffer are
// stored in the VCD file. After executing a $dumpflush task, dumping is
// resumed as before so no value changes are lost." ... "A common application
// is to call $dumpflush to update the dump file so an application program can
// read the VCD file during a simulation."
//
// The dump is read back DURING the simulation, after a $dumpflush, one
// character at a time ($fgetc), split into white-space separated tokens
// (§18.2: "The dump file is structured in a free format. White space is used
// to separate commands"). What a writer chooses is not printed: the date
// and version text are tested for a property, and a's identifier code, which
// §18.2.1 leaves to the writer, is read from its $var section and printed as
// the name a.
//
// HAND DERIVATION:
//   $dumpfile("b_18_2_3_8_lit.vcd") is a literal, so the $version section's
//   system_task, with its white space removed, contains the 31 characters
//   $dumpfile("b_18_2_3_8_lit.vcd")  -> version=1
//   a $date section with a non-empty date_text precedes $enddefinitions
//                                     -> date=1
//   a $timescale section precedes $enddefinitions -> timescale=1
//   $version precedes $enddefinitions -> (implied by version=1, which is only
//   counted in the header)
//   After $enddefinitions, each change of a with its time record (§18.1.3:
//   the dump starts at the end of time 0, so $dumpvars holds a = 0):
//     #0 a=0
//     #1 a=1
//   #2 is the reader's: it flushes at #2 before a changes again, and after
//   the flush a = 0 at #3 is dumped as before (the reader has already read,
//   so the transcript does not show it). Keywords and empty sections such
//   as `$dumpall $end` are not printed.
// gold: hand derivation, §18.1.3, §18.2.1 and §18.2.3.8 (above)
//! inherited IEEE 1364-2005 18.2.3.8 18.2.3.2 18.2.1 18.1.6
`timescale 1ns/1ns
module b_18_2_3_8_dut;
  reg a;
  initial begin
    a = 1'b0;
    #1 a = 1'b1;
    #2 a = 1'b0;
  end
endmodule

// Dumps u and reads the dump back; its own variables are not selected.
module b_18_2_3_8_version_names_dumpfile_literal;
  b_18_2_3_8_dut u();
  integer fd, c;
  integer section; // 0 none, 1 $date, 2 $version, 3 $timescale, 4 $comment
  integer header, date_words, date_ok, version_ok, timescale_ok;
  reg [8*64:1] tok;
  reg [8*31:1] win;
  integer len, clen, alen, field, code_next;
  reg [8*64:1] cand, code, mask, now, first;

  task token;
    begin
      if (section != 0) begin
        if (tok == "$end") section = 0;
        else if (section == 1) date_words = date_words + 1;
      end else if (tok == "$comment") section = 4;
      else if (header) begin
        // `$var var_type size identifier_code reference $end`
        if (tok == "$date") section = 1;
        else if (tok == "$version") section = 2;
        else if (tok == "$timescale") begin
          section = 3;
          timescale_ok = 1;
        end else if (tok == "$var") field = 1;
        else if (field == 3) begin cand = tok; clen = len; field = 4; end
        else if (field == 4) begin
          if (tok == "a") begin
            code = cand;
            alen = clen;
            mask = {512{1'b1}} >> (512 - 8 * clen);
          end
          field = 0;
        end else if (field != 0) field = field + 1;
        else if (tok == "$enddefinitions") header = 0;
      end else begin
        // After the header: a vector or real value's code is its own token,
        // so it is stepped over; `#` opens a time record; `$` a keyword; any
        // other token is a scalar change, a value digit then a code.
        first = tok >> 8 * (len - 1);
        if (code_next) code_next = 0;
        else if (first == "b" || first == "B" || first == "r" || first == "R") code_next = 1;
        else if (first == "#") now = tok;
        else if (first != "$" && alen != 0 && len == alen + 1 && (tok & mask) == code)
          $display("%0s a=%0s", now, first);
      end
      if (section == 0 && date_words != 0) date_ok = 1;
    end
  endtask

  initial begin
    $dumpfile("b_18_2_3_8_lit.vcd");
    $dumpvars(1, u);
    #2 $dumpflush;
    fd = $fopen("b_18_2_3_8_lit.vcd", "r");
    section = 0;
    header = 1;
    date_words = 0;
    date_ok = 0;
    version_ok = 0;
    timescale_ok = 0;
    tok = 0;
    win = 0;
    len = 0; clen = 0; alen = 0; field = 0; code_next = 0;
    cand = 0; code = 0; mask = 0; now = "#?"; first = 0;
    c = $fgetc(fd);
    while (c != -1) begin
      if (c == " " || c == "\n" || c == "\t" || c == 8'd13) begin
        if (len != 0) token;
        tok = 0;
        len = 0;
      end else begin
        tok = {tok, c[7:0]};
        len = len + 1;
        if (section == 2) begin
          win = {win, c[7:0]};
          if (win == "$dumpfile(\"b_18_2_3_8_lit.vcd\")") version_ok = 1;
        end
      end
      c = $fgetc(fd);
    end
    if (len != 0) token;
    $fclose(fd);
    $display("date=%0d version=%0d timescale=%0d", date_ok, version_ok, timescale_ok);
  end
endmodule
