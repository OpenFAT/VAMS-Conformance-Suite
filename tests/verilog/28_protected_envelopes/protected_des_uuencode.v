// Host profile: known_keys.json supplies public test keys, CBC IV and
// padding; `//@ protect-keys` hands it to the tool's key provider (VerA:
// --protect-keys). Oracle: verify_vectors.py decrypts the same envelope
// with OpenSSL; the cleartext prints decrypted=42 only if decrypted.
// gold: OpenSSL 3.6.2 decrypts the data_block (verify_vectors.py, or `openssl enc -d -des-cbc` with known_keys.json) to a $display of `PROTECTED_VALUE, defined 42 above: "decrypted=42" (§28.4)
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.9 28.4.9.1 28.4.9.2
`define PROTECTED_VALUE 42
module protected_des_uuencode;
`pragma protect begin_protected
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="uuencode",line_length=64,bytes=80)
`pragma protect data_block
M@';"*+WVW[WM\L$&O#UYG<DOQK5>(E\ZT2\>6PV0A(&U95",1^^^+C+N3L-V
CF_=8-WL-M=01+6B_NA>F[;DX)ITO"6-UJY!(0T&'7C"]O[L`
`
`pragma protect end_protected
endmodule
