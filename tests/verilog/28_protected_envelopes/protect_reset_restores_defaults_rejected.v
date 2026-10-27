// IEEE 1364-2005 §28.4.31.2: "Following the reset, all protect pragma
// keywords are restored to their default values." §28.3: "In protected
// envelopes where a specific pragma keyword is absent, the Verilog tool shall
// use the default value."
//
// protected_des_base64.v's data_block, its key directives moved before the
// envelope with a reset between them and it. The envelope names no key owner, key or
// method, so only the defaults apply, and clause 28 defines no default that
// names the user's des-fixture key: the data_block cannot be decrypted and
// "decrypted=42" must not run. A tool that ignored the reset would decrypt.
//
// Legal neighbour: protected_des_base64.v, whose key directives are inside
// the envelope.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.31.2
//! reject the envelope's key was reset; the data_block cannot be decrypted
`define PROTECTED_VALUE 42
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect reset
module protect_reset_restores_defaults_rejected;
`pragma protect begin_protected
`pragma protect encoding=(enctype="base64",line_length=64,bytes=80)
`pragma protect data_block
gHbCKL32373t8sEGvD15nckvxrVeIl860S8eWw2QhIG1ZVCMR+++LjLuTsN2m/dY
N3sNtdQRLWi/uhem7bk4Jp0vCWN1q5BIQ0GHXjC9v7s=
`pragma protect end_protected
endmodule
