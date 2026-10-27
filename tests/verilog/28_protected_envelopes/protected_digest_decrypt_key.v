// IEEE 1364-2005 §28.4.20.1: the syntax is the bare keyword
// `digest_decrypt_key`, and it "indicates that the next line contains the
// encoded value of the key that will decrypt the digest_block". §28.4.20.2:
// "the digest_key_method and digest_decrypt_key are encrypted using the
// key_method and stored in the output file as the contents of the
// key_block"; on decryption the tool "must decrypt the key_block to find the
// digest_decrypt_key and digest_key_method that in turn can be used to
// decrypt the digest block". §28.4.22.2: a digest_block "shall immediately
// follow the key_block or data_block to which it refers".
//
// protected_session_key_block.v's key_block, extended with a digest key. It
// decrypts (exchange-fixture) to:
//   `pragma protect data_method="des-cbc"
//   `pragma protect encoding=(enctype="base64",line_length=64,bytes=8)
//   `pragma protect data_decrypt_key
//   ASNFZ4mrze8=
//   `pragma protect digest_key_method="des-cbc"
//   `pragma protect encoding=(enctype="base64",line_length=64,bytes=8)
//   `pragma protect digest_decrypt_key
//   /ty6mHZUMhA=
// so the data key is 0123456789abcdef and the digest key fedcba9876543210.
// Each digest_block is the SHA-1 of its block's decrypted bytes, encrypted
// with the digest key, under known_keys.json's IV and padding. Oracle:
//   printf '%s' "$KEYBLOCK_CLEARTEXT" | openssl sha1 -binary | openssl enc
//   -des-cbc -K fedcba9876543210 -iv 1234567890abcdef | base64
// and the same for the data_block's cleartext, which prints decrypted=42.
// A digest mismatch has no outcome the clause requires, so this asserts
// that the key_block, digest key and all, is read and the data decrypts.
//@ protect-keys known_keys.json
//! inherited IEEE 1364-2005 28.4.20.1 28.4.20.2
`define PROTECTED_VALUE 42
module protected_digest_decrypt_key;
`pragma protect begin_protected
`pragma protect key_keyowner="VerAConformance"
`pragma protect key_keyname="exchange-fixture"
`pragma protect key_method="des-cbc"
`pragma protect digest_method="sha1"
`pragma protect encoding=(enctype="base64",line_length=64,bytes=312)
`pragma protect key_block
HmR1lmmwZqix46pT213GCLJGD4OtmME9U7vcCpo4YqZvYw+xhz92F0XGsaoWCFUk
7XX/HumQ/bJdtzV3L+V4hQ3xGQyD7cLJLKoHdUxF8U7PIUJWgVCgCzSqfXu4TQP0
iLgc2dAxR7SLK1htwsLXI/uy0zMeDaVolUPGaRbW/+aWxd3Tf1ZtBGXIMDkIJ0xS
q3071/nhOjSo/9Eb2gv3e7HxFXrM4TS2SE15E0GD8JEcaC0iro6aKyrlkb4osjlQ
b4UWhpuTdN04tYDnrbbrj+UtDTbDlXty+9kM7xnYQ8e7IPait0kqpDgelCW9YcAx
UQvMAHXAkI9pyfRdE75E3rC1KrYcAB4wY24GIsz6NIe5XxgDVgpru2s2thawBglq
X008Pg5N4cOU/N/X4jHd/rYLcmWvsCB/
`pragma protect encoding=(enctype="base64",line_length=64,bytes=24)
`pragma protect digest_block
QcnzcPxM6OaQOKgXHWfiEaeS8KZi4LB2
`pragma protect encoding=(enctype="base64",line_length=64,bytes=80)
`pragma protect data_block
gHbCKL32373t8sEGvD15nckvxrVeIl860S8eWw2QhIG1ZVCMR+++LjLuTsN2m/dY
N3sNtdQRLWi/uhem7bk4Jp0vCWN1q5BIQ0GHXjC9v7s=
`pragma protect encoding=(enctype="base64",line_length=64,bytes=24)
`pragma protect digest_block
iRM7BMo+TyISaFZ2SU/cwn3BCebCzX3m
`pragma protect end_protected
endmodule
