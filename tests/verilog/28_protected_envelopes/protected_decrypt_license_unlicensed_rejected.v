// IEEE 1364-2005 §28.4.28.2: "After encountering a decrypt_license pragma
// expression in an encrypted model, prior to processing the decrypted text,
// the application shall load the specified library and call the entry
// function [...] If the application is licensed to decrypt the model, the
// returned value shall compare equal to the match value [...] If the
// application is not licensed to decrypt the model, no decryption shall be
// performed, and the application shall produce an error message".
//
// The data_block holds §28.4.28.1's form, as the clause says it "will
// typically be found", ahead of the statement that prints decrypted=42:
//   `pragma protect decrypt_license=(library="conform_no_such_license.so",entry="conform_license_check",feature="conform",match=1)
//   initial begin $display("decrypted=%0d",`PROTECTED_VALUE); $finish(0); end
// The library does not exist, so no entry function can return the match
// value: the model is not licensed and must not be decrypted.
//
// Host profile: known_keys.json (des-fixture). Oracle:
//   printf '%s\n%s\n' "$LINE1" "$LINE2" | openssl enc -des-cbc
//   -K 0123456789abcdef -iv 1234567890abcdef | base64
// Legal neighbour: protected_des_base64.v.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.28.1 28.4.28.2
//! reject the decrypt_license library cannot be loaded; the model is not licensed
`define PROTECTED_VALUE 42
module protected_decrypt_license_unlicensed_rejected;
`pragma protect begin_protected
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=208)
`pragma protect data_block
CEwlPH76i0/T4ErznDzLTXiO/fE6M6hG3GhSHNfS7/xDln8Ij9YhlEC2TLPQKYxC
hG4qy6bP1qB6zqOWecX0Tkopvo2bcPnvdT3RFlGPPspb3jQCeLLp9L2PE34ts30q
wpIah5nprn329Antw8m2uDn3gpXU3pmzdELcd/ISwHXhmtc7SnQ7p5pFSxFd1IYg
mVcEcMroeywajRVySb/t8Av75t/ns+O8xud5bDBCyyJITkuBnptUIcDApUnKtMx4
AtQkuPkWAmn7ZQ1bmkIy+g==
`pragma protect end_protected
endmodule
