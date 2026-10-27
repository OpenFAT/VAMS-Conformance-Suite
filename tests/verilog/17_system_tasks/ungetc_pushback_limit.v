// IEEE 1364-2005 §17.2.4.1: $ungetc "inserts the character specified by c
// into the buffer specified by file descriptor fd. The character c shall be
// returned by the next $fgetc call on that file descriptor. ... If an error
// occurs pushing a character onto a file descriptor, then code is set to
// EOF. Otherwise, code is set to zero." Its NOTE: "The features of the
// underlying implementation of file I/O on the host system limit the number
// of characters that can be pushed back onto a stream." The limit is the
// host's, so this does not count pushes; it checks what holds for each one:
// code is 0 or EOF (-1), and after a 0 the next $fgetc returns the character.
//
// HAND DERIVATION. The file holds the 26 letters and a newline. 20 $fgetc
// calls read "a" to "t". Then three times: push "Z" (90) and read once. Each
// push that returns 0 must be followed by 90; one that returns EOF leaves
// the file's next character, "u" (117), "v", "w" in turn. Either way the
// line prints ok=1 for each.
// gold: Icarus Verilog 13.0 agrees
//! inherited IEEE 1364-2005 17.2.4.1
module b_17_2_4_1_ungetc_pushback_limit;
  integer fd, c, k, code, next, expect;
  initial begin
    fd = $fopen("b_17_2_4_1_ungetc_pushback_limit.dat", "w");
    $fwrite(fd, "abcdefghijklmnopqrstuvwxyz\n");
    $fclose(fd);
    fd = $fopen("b_17_2_4_1_ungetc_pushback_limit.dat", "r");
    for (k = 0; k < 20; k = k + 1) c = $fgetc(fd);
    expect = 117;
    for (k = 0; k < 3; k = k + 1) begin
      code = $ungetc(90, fd);
      next = $fgetc(fd);
      if (code == -1) begin
        $display("ok=%0d", next == expect);
        expect = expect + 1;
      end else
        $display("ok=%0d", code == 0 && next == 90);
    end
    $fclose(fd);
    $finish(0);
  end
endmodule
