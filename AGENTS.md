# AGENTS.md

VAMS Conformance Suite: tests for Verilog-AMS, Verilog-A (Annex C), IEEE
1364-2005 and Annex E SPICE, plus pinned upstream suites, run against any
tool by one C harness, `conform`. The harness knows no tool; a tool is a
config file of shell commands. `README.md` is the contract: the `//!` and
`//@` directives, the verdict rules, the config variables.

## Skills to load first

Load each with the Skill tool (other agents: read
`~/.claude/skills/<name>/SKILL.md` and the companion files it names). Source:
https://github.com/OmarSiwy/NixOSConfig/tree/main/skills

| Skill | Use it for here |
|---|---|
| `data-oriented-design` | `harness/conform.c`'s test and verdict tables, the manifests' rows |
| `codebase-clean-code` | Owners: `harness/` judges, `tools/` adapts one tool each, `tests/` and `external/` hold the inputs; the harness never learns a tool's name |
| `api-design` | The tool-facing contract (`stage.language` commands, `CONFORM_*` variables, exit 77) and the test-facing one (`//!`, `//@`): usage first |
| `ponytail` (ultra) | How little code; never what shape the data takes |
| `assertions` | Contracts and bounded loops in `conform.c` |
| `test-plan`, `tdd` | This repo is an oracle set: what each test proves, the gates, a test's definition of done |

Project-specific:

| Skill | Use it for here |
|---|---|
| `writing-perfect-verilog` | Every `.v`, `.va` and `.vams` test |
| `spice-engine` | `tests/netlist/` and `tools/rawcheck.py`: `.expected.json` oracles and tolerances that follow the reference's own accuracy |

## The method

Binding on every change, in every project.

### Code

- Five commitments: lean storage, no runtime residue, cheap change,
  contained failure, proof by test.
- Answer the six data questions before writing code. Then: one array per
  field, the narrowest width the stated range allows, typed `u32` handles
  with a sentinel, existence tables instead of flags, hot/cold split, tables
  sized once from a named capacity, a compile-time size assertion on every
  hot struct.
- An abstraction on a hot path carries an assembly probe: FOLDED, IDENTICAL,
  EQUIVALENT or NEGATIVE pass; RESIDUE fails the build. A "no residue" claim
  cites the probe, a speed claim cites a benchmark. Dispatch per batch, never
  per element.
- A seam names what varies and needs a second case today; it sits on the
  cheapest rung (concrete, free function, table, closed enum with exhaustive
  switch, comptime, request table, function-pointer table, `dyn`, plugin).
- Tables, transforms, one spine per pipeline (ifs up, fors down), one owner
  writes each table and everyone else appends requests. Three likely changes
  each have a change radius of zero; the compiler lists every other site.
- APIs start from the caller's code. The caller owns memory and flow:
  requests instead of callbacks, an immediate twin for anything retained.
  Factor at the second real instance.
- Branches: delete, then branchless, then vectorize along a lane axis. The
  `W == 1` instantiation is the scalar oracle; vectorization is verified in
  the assembly.
- GPU: SoA always, the roofline ceiling named with its arithmetic before
  tuning, data kept on the device, fixed-order reductions, the dependency DAG
  recovered before porting. "This belongs on the CPU" is a valid verdict.
- An operating error returns to the caller that can decide; a bug hits an
  assertion. Two or more split, paired assertions per function, a bound on
  every loop, input validated once at the edge, fallible work before the
  commit.
- Pass order: boundary, placement, data, zero-cost proof, contracts, tests,
  branches, lanes. Data layout beats brevity. Every pass keeps NaN gates,
  allocation-failure paths, `errdefer`s, trust-boundary validation and
  tolerances.

### Testing

- The oracle is named before the code and never recomputes the answer the
  way the code does. Cheapest first: assertions, a reference
  implementation, a round trip, a certificate, a metamorphic relation, a
  model, a golden with recorded provenance, a spec example.
- The main bug class is a wrong number with no crash, which coverage and
  fuzzing cannot see. A bug found by a person is a hole in the oracle set:
  it lands with its regression test and the oracle or generator that would
  have caught its class.
- A new test goes red on the bug before it is trusted green.
- Unsupported fails and never skips. A known failure stays a failure: no
  baseline marks it expected, so it shows until it is fixed. Name lists are
  compared, never counts.
- A tolerance follows the oracle's own accuracy. Determinism is a test:
  1 job and N jobs give the same bytes, and the order is fixed, not the test.
- A flaky test is fixed or quarantined the same day, never retried
  silently.
- Tiers: pre-commit under 10 s, merge under 15 min, nightly, release. A
  release ships on numbers a script checks. The map lives in `TESTING.md`.

### Builds

- A build is a cache keyed on its declared inputs. Every producing step has
  an output argument, every checking step an exit-code check, every file
  read at run time is declared (`addFileInput`) or the step says
  `has_side_effects`. Keys hash contents, never absolute paths.
- Cut the artifact graph where edits land: one object per generated unit,
  narrow imports for shared ones, kernels out of host graphs.
- Zig edit loop: `zig build check --watch -fincremental`, one watch per
  artifact across all worktrees; the result that counts comes from a plain
  build. One global cache per toolchain store path; a worktree symlinks its
  `.zig-cache` to the main checkout's.
- Rust: flags live in `.cargo/config.toml`, never a one-off `RUSTFLAGS`;
  `check`, `build`, `test` and rust-analyzer agree on features, profile and
  target directory (rust-analyzer gets its own).
- Nothing collects a cache. Keep a byte budget per cache and delete old
  entries only while no build runs (the `long-term-garbage-collection`
  skill); a warm cache is kept, never wiped by routine.
- Gate on the exit code: `cmd | tail` swallows it, so use
  `exit "${PIPESTATUS[0]}"`.

### Maintaining

- `main` is green by machine: work lands through a pull request whose merge
  result passed the required checks. Work collects on the `development`
  branch and lands on `main` through that pull request; other topic branches
  are deleted after the merge.
- Bots never push to `main`. Generated output ships as a release asset or
  through a gated pull request.
- Every dependency is pinned by commit and content hash, the toolchain by
  `flake.lock`, actions by SHA. A third-party input you hash is mirrored
  somewhere you control.
- The changelog is written by hand, one line per change citing its issue,
  every number in it measured. A release refuses a version mismatch, builds
  every target, checks every artifact and smokes the bundle.
- CI holds: the merge gate, every target compiled, docs that execute,
  reference suites gated by name, a nightly, the downstream contracts, the
  release job.

## Building

- Run inside `nix develop -c …`: it carries `conform`, openvaf-r, ngspice,
  iverilog and verilator. Without Nix:
  `cc -O2 -o conform harness/conform.c -lm`.
- `harness/selftest.sh` (also `nix flake check`) drives the harness with a
  scripted fake tool and checks every verdict. Run it after any change to
  `harness/`.
- One tool over the suite:
  `conform -t tools/<tool>.conf -j 16 tests/<language>`.
- `conform` exits 1 on any FAIL or XPASS.
- Clone submodules with `--shallow-submodules`, never `--recursive`: sv-tests
  nests LLVM and Yosys and fills the disk.

## Testing

- Every test cites the clause it checks (`//! lrm 4.5.7`) and is named after
  the behaviour; a prohibition ends in `_rejected` and names its legal twin
  with `//! neighbour`.
- A run test checks a value with `CHECK`, an `.expected.txt` or an
  `.expected.json` whose provenance (tool, version, command, or derivation)
  is in the file. A gold written by the tool under test is no oracle.
- No tool has an xfail baseline: a tool's failures stay FAILs, on purpose,
  until the tool is fixed. Exit 77 (SKIP) is only for a test the tool cannot express.
- Check that a new test goes red on a wrong tool (a broken adapter, the
  `_rejected` twin) before trusting it green.

## Committing

Commit at every green step: `harness/selftest.sh` passing and every new or
changed test checked against its oracle; a tool failing a correct test does
not make the step red. The message names the clause or
tool. The README's charts and `docs/conformance` are written by the
`conformance` workflow; leave them to it. Never commit red to `main`.
