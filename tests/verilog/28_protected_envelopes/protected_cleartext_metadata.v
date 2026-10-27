// IEEE 1364-2005 §28.4.5.2, §28.4.6.2: author and author_info "shall be
// placed in a pragma directive enclosed within the protected envelope, but
// shall not be encrypted into the data_block"; §28.4.7.2, §28.4.8.2 say the
// same of encrypt_agent and encrypt_agent_info. §28.4.30.2: the comment
// "shall be output in cleartext immediately prior to the data_block". All
// five say "DECRYPTION INPUT: none". This is the envelope an encrypting tool
// writes with them; they must not stop or change its decryption.
//
// Host profile: known_keys.json. The data_block is protected_des_base64.v's,
// which verify_vectors.py checks; the cleartext prints decrypted=42.
// gold: OpenSSL 3.6.2 decrypts the data_block (verify_vectors.py, or `openssl enc -d -des-cbc` with known_keys.json) to a $display of `PROTECTED_VALUE, defined 42 above: "decrypted=42" (§28.4)
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.5.2 28.4.6.2 28.4.7.2 28.4.8.2 28.4.30.2
`define PROTECTED_VALUE 42
module protected_cleartext_metadata;
`pragma protect begin_protected
`pragma protect author="Conformance Author"
`pragma protect author_info="Cleartext author information"
`pragma protect encrypt_agent="Conformance Encryptor"
`pragma protect encrypt_agent_info="Cleartext agent information"
`pragma protect data_keyowner="VerAConformance"
`pragma protect data_keyname="des-fixture"
`pragma protect data_method="des-cbc"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=80)
`pragma protect comment="Copyright notice kept out of the data_block"
`pragma protect data_block
gHbCKL32373t8sEGvD15nckvxrVeIl860S8eWw2QhIG1ZVCMR+++LjLuTsN2m/dY
N3sNtdQRLWi/uhem7bk4Jp0vCWN1q5BIQ0GHXjC9v7s=
`pragma protect end_protected
endmodule
