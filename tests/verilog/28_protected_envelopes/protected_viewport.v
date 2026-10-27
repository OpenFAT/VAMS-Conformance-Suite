// IEEE 1364-2005 §28.4.32.1: viewport = ( object = <string> , access =
// <string> ). §28.4.32.2: "The specified object name shall be contained
// within the current envelope. The access value is an implementation-
// specified relaxation of protection." What the access permits is the
// tool's, so this asserts only that a well-formed viewport naming an object
// of the envelope leaves its decryption alone.
//
// The data_block decrypts (des-fixture) to:
//   reg hidden_r;
//   initial begin hidden_r = 1'b1; $display("decrypted=%0d",`PROTECTED_VALUE); $finish(0); end
// Oracle: printf '%s\n%s\n' "$LINE1" "$LINE2" | openssl enc -des-cbc
//   -K 0123456789abcdef -iv 1234567890abcdef | base64
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.32.1
`define PROTECTED_VALUE 42
module protected_viewport;
`pragma protect begin_protected
`pragma protect viewport=(object="hidden_r",access="read")
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=112)
`pragma protect data_block
nzb3F4uhkOENFkepE44U/q23lFg4Mugy/LerOjBVR6Jx9fgfsyD4dCK5ikndN/NQ
BLDKUifSApGTLPrrq50Qy+mDph3Kr/s7oU79k2b+9hc3EKPsbtz50t/psiSGCnBp
UQcIG1F9p/ZLe88vleQtFg==
`pragma protect end_protected
endmodule
