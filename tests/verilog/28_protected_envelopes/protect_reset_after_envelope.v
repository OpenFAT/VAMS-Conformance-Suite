// IEEE 1364-2005 §28.4.31.1: the syntax is the bare keyword `reset`. §28.3:
// "Further robustness can be achieved by appending a reset pragma keyword
// after each envelope", which this does, as §28.2.1's example does with the
// equivalent `pragma reset protect. The reset must not undo the envelope it
// follows.
//
// Host profile: known_keys.json. The data_block is protected_des_base64.v's,
// which verify_vectors.py checks; the cleartext prints decrypted=42.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.31.1
`define PROTECTED_VALUE 42
module protect_reset_after_envelope;
`pragma protect begin_protected
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=80)
`pragma protect data_block
gHbCKL32373t8sEGvD15nckvxrVeIl860S8eWw2QhIG1ZVCMR+++LjLuTsN2m/dY
N3sNtdQRLWi/uhem7bk4Jp0vCWN1q5BIQ0GHXjC9v7s=
`pragma protect end_protected
`pragma protect reset
endmodule
