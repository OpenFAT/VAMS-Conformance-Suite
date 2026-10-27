// IEEE 1364-2005 §28.4.29.2: "After encountering a runtime_license pragma
// expression in an encrypted model, prior to executing, the application shall
// load the specified library and call the entry function [...] If the
// application is licensed to execute the model, the returned value shall
// compare equal to the match value [...] If the application is not licensed
// to execute the model, execution shall not begin, and the application shall
// produce an error message".
//
// The data_block holds §28.4.29.1's form, as §28.2.1's example places it,
// ahead of the statement that prints decrypted=42:
//   `pragma protect runtime_license=(library="conform_no_such_license.so",entry="conform_license_check",feature="conform",match=1)
//   initial begin $display("decrypted=%0d",`PROTECTED_VALUE); $finish(0); end
// The library does not exist, so no entry function can return the match
// value: the model is not licensed and must not execute. The clause lets the
// check fall at compile time or before the run, so either refusal passes.
//
// Host profile: known_keys.json (des-fixture). Oracle:
//   printf '%s\n%s\n' "$LINE1" "$LINE2" | openssl enc -des-cbc
//   -K 0123456789abcdef -iv 1234567890abcdef | base64
// Legal neighbour: protected_des_base64.v.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.29.1 28.4.29.2
//! reject the runtime_license library cannot be loaded; the model is not licensed
//! reject-run
`define PROTECTED_VALUE 42
module protected_runtime_license_unlicensed_rejected;
`pragma protect begin_protected
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=208)
`pragma protect data_block
CEwlPH76i0/T4ErznDzLTf2CoUC4gdarIYnP3ZIMKbeRxjsdv/x8H+zb4RaDmUO4
ULYtuISG0nD19QD/aorEx0YrwEV1U+NDWLRgfN9euPaQxhVpJarYHOB3AXw/C9+B
MHmS/iq1WAiWTjrMkkf06n4FoQkaT8pNTkEENXwHMseQ9Q2IsWmlFoKDmGO9nveg
z8hbO6ea5RP5gmygZMPWw0fh7exXfwMBqJLprLdpRQC2h1g/TDQYa7GIV/z2pEj4
W6fwSNhE7ICToV99Da2pGQ==
`pragma protect end_protected
endmodule
