// IEEE 1364-2005 §17.2.9, an input the clause does not allow.
// audit_readmem_invalid_punctuation.txt holds `;`. "The text file to be read
// shall contain only the following: White space (spaces, newlines, tabs, and
// formfeeds), Comments (both types of comment are allowed), Binary or
// hexadecimal numbers"; a `;` is none of them.
//
// §1.2 a): "the term shall denotes a requirement that the standard imposes.
// The resulting implementation is required to enforce the requirements and to
// issue an error if the requirement is not met by the input." So the load
// must issue an error message. §17.2.9 says what follows such an error only
// for a file address outside the task's range ("the load operation is
// terminated"); for this input it leaves open what the memory holds, whether
// the simulation goes on and its exit status, so the test checks only that
// the tool printed a message. The test prints nothing itself.
//
// Legal neighbour: readmem_malformed_legal_neighbors.v loads 11 and 10.
//! inherited IEEE 1364-2005 17.2.9 1.2
//! exit any
//! diagnostic
//! neighbour readmem_malformed_legal_neighbors.v
module readmem_malformed_punctuation_error;
  reg [7:0] mem [0:0];
  initial $readmemh("audit_readmem_invalid_punctuation.txt", mem);
endmodule
