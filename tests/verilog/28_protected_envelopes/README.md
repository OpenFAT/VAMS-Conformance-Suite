# Protected-envelope regressions

The five `protect_*_metadata.v` cases assert acceptance of legal metadata
around ordinary unprotected HDL. Their scope is syntax acceptance; they do
not establish encryption-service behavior.

The six `protected_*.v` cases contain real DES-CBC ciphertext, with base64
and historical uuencoding, SHA-1/MD5 digests, a session-key block, or eight
nested envelopes. The decrypted statement expands a macro from outside the
envelope and must print `decrypted=42`. Ignoring an envelope cannot pass.
`verify_vectors.py` decrypts and checks the test data independently using
OpenSSL, including the recorded digests.

`known_keys.json` contains **public test keys** and the exact test-host
profile. IEEE 1364 specifies the algorithms but does not standardize key
provisioning, CBC IV transport, padding, or a tool's invocation spelling.
The profile chooses these details explicitly. It is not a claim that every
vendor accepts the same encrypted file without an adapter.

Each of the six names the profile with `//@ protect-keys known_keys.json`,
which the harness hands to the tool's key-provider interface (VerA's
`--protect-keys FILE`). A failure at key lookup (VerA E0152) is reported
apart from a failed cryptographic comparison (E0153).

Encryption-service round trips, asymmetric public-key serialization,
licensing callbacks and viewport access need further host profiles. Their
remaining obligations are listed in `vera/ledger/GAPS.tsv`; neither
these inputs nor syntax acceptance earns passing evidence for them.
