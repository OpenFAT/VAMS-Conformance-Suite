// IEEE 1364-2005 §28.3: "The scope of protect pragma directives is
// completely lexical and not associated with any declarative region or
// declaration in the HDL text itself." §28.4.31.2: "the scope of pragma
// definitions is lexical and extends from the point of the directive until
// the end of the compilation input". The key and method are given once,
// before the module; the envelope that follows relies on them.
//
// Host profile: known_keys.json. The data_block is protected_des_base64.v's,
// which verify_vectors.py checks; the cleartext prints decrypted=42.
// Rejected twin: protect_reset_restores_defaults_rejected.v.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.3
`define PROTECTED_VALUE 42
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
module protected_keywords_before_envelope;
`pragma protect begin_protected
`pragma protect encoding=(enctype="base64",line_length=64,bytes=80)
`pragma protect data_block
gHbCKL32373t8sEGvD15nckvxrVeIl860S8eWw2QhIG1ZVCMR+++LjLuTsN2m/dY
N3sNtdQRLWi/uhem7bk4Jp0vCWN1q5BIQ0GHXjC9v7s=
`pragma protect end_protected
endmodule
