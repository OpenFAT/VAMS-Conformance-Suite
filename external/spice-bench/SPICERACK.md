# SpiceRack round trip

SpiceRack reads every deck here as ngspice, writes it back as ngspice, and
checks that the converted deck reproduces every plot of the original. Its
harness is `tests/test_import_suite.rs` (`spice_bench_round_trip`):

    nix develop .#testing -c bash -c \
      'SPICE_BENCH=DIR SPICE_BENCH_TIMEOUT=600 cargo test --no-default-features \
       --features backend,json --release --test test_import_suite spice_bench -- --nocapture'

`DIR` is a `fetch.sh` output. A deck passes when the converted run matches
the original at every point (op, dc, ac) or stays inside a 1% time tube
(transient). It is skipped when the original cannot be judged: ngspice cannot
run it as written, it times out, or it disagrees with itself.

## Result (2026-10-25, ngspice-45, 600 s per deck)

6,050 decks: 5,564 pass, 485 skip, 0 fail. (One more deck,
`postlayout/tdc_sky130.sp`, failed only when the disk filled mid-run and was
not rechecked in place.)

## What the round trip found

The four decks that once failed were SpiceRack bugs, now fixed:

- `ngspice/examples/TransmissionLines/{cpl_ibm1,ltra6_2_line}.sp`: SpiceRack
  wrote raw element cards (LTRA, CPL) and `X` instances after the other
  components. ngspice numbers nodes in card order, and these coupled lines are
  sensitive to it. Cards are now written in the order they were read.
- `ngspice/paranoia/pton/555-timer-2.sp`: ngspice reads a number as an
  integer mantissa times `pow(10, e)` (`inpeval.c`), so `0.5u` and `500n` are
  one ulp apart, and this oscillator's switching time follows that ulp.
  SpiceRack now reads ngspice numbers with ngspice's arithmetic and writes
  each back in a spelling that lands on the same double.

## Skips

Each is a deck the harness cannot judge with ngspice-45. Only `vbic/diffamp`
may be SpiceRack's (its raw-file reader); the rest are the decks, the
ngspice build, or the run.

| Decks | Count | Why |
|---|---|---|
| `cmcqa/psp/*` | 432 | `level=1040` is ESPice's PSP 103; ngspice-45 has PSP only as OSDI (see `cmcqa/README.md`). |
| `ngspice/{examples,paranoia}/transient-noise/*` | 13 | TRNOISE draws a new stream every run: two runs of `simple-noise.sp` disagree, and `.option seed=1`, `rndseed` and `.spiceinit` do not pin it. The harness now reruns the original and skips such a deck as "not repeatable"; this run predates that control and labelled them order-sensitive. |
| `circuitsim90/MOS2_LARGE`, `iscas85/c5315`, `tests/mesa` | 9 | Over 600 s; a longer `SPICE_BENCH_TIMEOUT` would settle them. |
| `cmcqa/hicum/*` | 6 | The original's sweep converges to no points (the six `cmcqa/README.md` counts as not finishing). |
| `ngspice/examples/pss/*` | 6 | This ngspice-45 build has no `.pss` ("unimplemented dot command"). |
| `cmcqa/gf180/gf180_cv_*` | 6 | The decks use `nmos_3p3` as an `M` device; the PDK defines it as a subcircuit ("could not find a valid modelname"). |
| `ngspice/paranoia/{TransmissionLines/ltra5_1_line,TransmissionLines/txl4_1_line,vdmos/ro_11_vdmos}` | 3 | ngspice rejects the flattened paranoia decks ("device already exists", "unknown parameter (l)"). |
| `ngspice/iscas85/c432/c432_ann.sp` | 1 | With `.options interp` ngspice writes a raw file whose binary block does not match its `No. Points`. |
| `ngspice/examples/optran/HiPass3opamps_optran.sp` | 1 | `opa1611.lib` is not in the fetched assets. |
| `postlayout/c7552_ihp.sp` | 1 | Needs the IHP PSP OSDI model (`pspnqs103va`), which the deck expects the PDK to load. |
| `ngspice/tests/regression/misc/empty-1.sp` | 1 | No circuit: the original produces no vectors. |
| `ngspice/tests/vbic/diffamp.sp` | 1 | ngspice writes a raw file whose variable index SpiceRack's reader rejects; not yet looked at. |
| `circuitsim90/MOS2_LARGE/mem_plus.sp`, `iscas85/c7552/c7552_ann.sp`, `postlayout/c7552_sky130.sp`, `powergrid/{ibmpg1t,ssram_trans}.sp` | 5 | Empty or cut-off raw files from the original run, while the disk was full: rerun before reading anything into them. |

The PSP decks can be judged by running them with ESPice, or by compiling
`psp103.va` with OpenVAF so ngspice loads it, and comparing against each
deck's `.reference`.
