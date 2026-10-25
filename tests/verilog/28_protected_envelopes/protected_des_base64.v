// Host profile: known_keys.json supplies public test keys, CBC IV and
// padding; `//@ protect-keys` hands it to the tool's key provider (VerA:
// --protect-keys). Oracle: verify_vectors.py decrypts the same envelope
// with OpenSSL; the cleartext prints decrypted=42 only if decrypted.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28 28.1 28.2 28.2.2 28.3 28.4 28.4.3 28.4.3.1 28.4.3.2 28.4.4 28.4.4.1 28.4.4.2 28.4.9 28.4.9.1 28.4.9.2 28.4.10 28.4.10.1 28.4.10.2 28.4.11 28.4.11.1 28.4.11.2 28.4.12 28.4.12.1 28.4.12.2 28.4.15 28.4.15.1 28.4.15.2
`define PROTECTED_VALUE 42
module protected_des_base64;
`pragma protect begin_protected
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=80)
`pragma protect data_block
gHbCKL32373t8sEGvD15nckvxrVeIl860S8eWw2QhIG1ZVCMR+++LjLuTsN2m/dY
N3sNtdQRLWi/uhem7bk4Jp0vCWN1q5BIQ0GHXjC9v7s=
`pragma protect end_protected
endmodule
