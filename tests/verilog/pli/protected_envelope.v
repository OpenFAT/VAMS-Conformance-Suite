// The design of protected_envelope.c: hidden_r and its initial statement are
// a decryption envelope's cleartext (IEEE 1364-2005 §28.2), clear_r is not.
// The envelope's key profile is the one 28_protected_envelopes uses.
// Oracle: `printf "  reg hidden_r;\n  initial hidden_r = 1'b1;\n" | openssl
// enc -des-cbc -K 0123456789abcdef -iv 1234567890abcdef | base64` is the
// data_block.
//@ protect-keys ../28_protected_envelopes/known_keys.json
module p_protected;
  reg clear_r;
`pragma protect begin_protected
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=48)
`pragma protect data_block
4oTj5HY7eVAQ7qaZw1AwkXw6q30w6OdpkCpsCIQv12EUFzY5B30l8IryvGG5jPIE
`pragma protect end_protected
  initial clear_r = 1'b0;
endmodule
