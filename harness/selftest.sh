#!/bin/sh
# The harness fed a fake tool whose behaviour each test scripts beside itself
# (<stem>.out is printed, <stem>.exit is the exit status). Every verdict is
# known in advance; any other verdict fails this script.
# usage: sh harness/selftest.sh [path/to/conform]
set -eu
CONFORM=${1:-$(dirname "$0")/conform}
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/s/include" "$T/s/verilog-a" "$T/s/verilog" "$T/s/spice"

cat > "$T/tool.conf" <<'EOF'
run.verilog-a = cat "$CONFORM_DIR/$CONFORM_STEM.out" 2>/dev/null; s=$(cat "$CONFORM_DIR/$CONFORM_STEM.exit" 2>/dev/null || echo 0); [ "$s" = segv ] && kill -SEGV $$; [ "$s" = hang ] && sleep 30; [ "$s" = hog ] && exec "$CONFORM_DIR/../../mem" 512 512 30000; [ "$s" = reserve ] && exec "$CONFORM_DIR/../../mem" 2048 16 300; exit $s
run.verilog = [ -z "$CONFORM_COMPILE_ONLY" ] || exit 0; cp "$CONFORM_DIR/$CONFORM_STEM.file" out.txt 2>/dev/null; cat "$CONFORM_DIR/$CONFORM_STEM.out" 2>/dev/null; cat "$CONFORM_DIR/$CONFORM_STEM.err" >&2 2>/dev/null; ${CONFORM_STD:+echo std=$CONFORM_STD}; ${CONFORM_PROTECT_KEYS:+echo keys=${CONFORM_PROTECT_KEYS##*/}}; ${CONFORM_NEGATIVE_TIMING:+echo negative-timing=$CONFORM_NEGATIVE_TIMING}; exit $(cat "$CONFORM_DIR/$CONFORM_STEM.exit" 2>/dev/null || echo 0)
run.vpi = echo "$CONFORM_LANG $(basename "$CONFORM_SRC")"
EOF
printf 'compile.verilog-a = exit 0\n' > "$T/compile-only.conf"
# mem R T MS: reserve R MiB, touch T of them, hold them MS ms, print "held".
${CC:-cc} -o "$T/mem" -x c - <<'EOF'
#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
int main(int argc, char **argv) {
    if (argc != 4) return 2;
    size_t reserve = strtoul(argv[1], 0, 10) << 20, touch = strtoul(argv[2], 0, 10) << 20;
    char *p = mmap(0, reserve, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    if (p == MAP_FAILED) return 1;
    memset(p, 1, touch);
    usleep(atoi(argv[3]) * 1000);
    puts("held");
    return 0;
}
EOF

# case <dir> <name> <directives> <stdout> <exit>
case_() {
    printf '%b\nmodule %s; endmodule\n' "$3" "$2" > "$T/s/$1/$2.va"
    printf '%b' "$4" > "$T/s/$1/$2.out"
    echo "$5" > "$T/s/$1/$2.exit"
}
case_ verilog-a pass '//! bias V(p) = 1\n`CHECK("x", 1, 1, 0);' 'x ok=1\n' 0
case_ verilog-a wrong_want '//! bias V(p) = 1' 'x ok=1\ny ok=0\n' 0
case_ verilog-a checks_off_by_one '//! checks 2' 'x ok=1\n' 0
case_ verilog-a no_assertion_ran '//! lrm 4.1\n`CHECK("x", 1, 1, 0);' '' 0
case_ verilog-a run_failed '//! bias V(p) = 1' '' 1
case_ verilog-a reject_ok '//! reject E0001' '' 1
case_ verilog-a reject_accepted '//! reject E0001' '' 0
case_ verilog-a reject_crash '//! reject E0001' '' segv
case_ verilog-a reject_run_ok '//! reject-run out of range' '' 1
case_ verilog-a exit_code '//! exit 3' '' 3
# `//! exit any`: any status 0..125, the output still judged; a crash fails.
case_ verilog-a exit_any '//! exit any\n//! stdout loaded 2' 'loaded 2\n' 1
case_ verilog-a exit_any_crash '//! exit any\n//! stdout loaded 2' 'loaded 2\n' segv
case_ verilog-a exit_any_wrong_output '//! exit any\n//! stdout loaded 2' 'loaded 3\n' 0
# `//! diagnostic`: a line the test did not print itself, on either stream.
case_ verilog-a diagnostic '//! exit any\n//! diagnostic\n//! stdout mem 11' 'mem 11\nreadmem: bad digit\n' 1
case_ verilog-a diagnostic_silent '//! exit any\n//! diagnostic\n//! stdout mem 11' 'mem 11\n\n' 0
case_ verilog-a stdout_line '//! stdout t=20 reached' 'p: t=20 reached\n' 0
case_ verilog-a timeout '//! bias V(p) = 1' '' hang
case_ verilog-a xfail '//! bias V(p) = 1' 'ok=0\n' 0
case_ verilog-a xpass '//! bias V(p) = 1' 'ok=1\n' 0
case_ verilog-a tool_cannot '//! bias V(p) = 1' '' 77
# -M 128 below: a tool that touches 512 MiB fails a reject test it would
# "reject" when killed; one that reserves 2048 MiB and touches 16 passes.
case_ verilog-a reject_out_of_memory '//! reject E0001' '' hog
case_ verilog-a big_reservation '//! stdout held' '' reserve
case_ spice no_command '//! bias V(p) = 1' '' 0
printf 'module g; endmodule\n' > "$T/s/verilog/golden.v"
printf 'hi\n' > "$T/s/verilog/golden.expected.txt"
printf 'hi\n' > "$T/s/verilog/golden.out"
printf 'module h; endmodule\n' > "$T/s/verilog/golden_diff.v"
printf 'hi\n' > "$T/s/verilog/golden_diff.expected.txt"
printf 'ho\n' > "$T/s/verilog/golden_diff.out"
printf 'module support; endmodule\n' > "$T/s/verilog/support_only.v"
# A design its same-stem VPI application names runs as that application.
printf 'module app; endmodule\n' > "$T/s/verilog/app.v"
printf '//! design app.v\n' > "$T/s/verilog/app.c"
printf 'vpi app.c\n' > "$T/s/verilog/app.expected.txt"
# `//! expect stdout F` names the gold; a name that is not there fails.
printf '//! expect stdout named.gold.txt\nmodule n; endmodule\n' > "$T/s/verilog/named_gold.v"
printf 'hi\n' > "$T/s/verilog/named.gold.txt"
printf 'hi\n' > "$T/s/verilog/named_gold.out"
printf '//! expect stdout gone.expected.txt\nmodule n; endmodule\n' > "$T/s/verilog/named_gold_missing.v"
printf 'hi\n' > "$T/s/verilog/named_gold_missing.out"
# `//@ protect-keys F` reaches the tool as CONFORM_PROTECT_KEYS.
printf '//@ protect-keys k.json\nmodule k; endmodule\n' > "$T/s/verilog/keys.v"
printf '{}\n' > "$T/s/verilog/k.json"
printf 'keys=k.json\n' > "$T/s/verilog/keys.expected.txt"
# `//@ negative-timing` reaches the tool as CONFORM_NEGATIVE_TIMING=1; it takes no argument.
printf '//@ negative-timing\nmodule nt; endmodule\n' > "$T/s/verilog/negative_timing.v"
printf 'negative-timing=1\n' > "$T/s/verilog/negative_timing.expected.txt"
printf '//@ negative-timing on\nmodule nt; endmodule\n' > "$T/s/verilog/negative_timing_argument.v"
printf 'negative-timing=1\n' > "$T/s/verilog/negative_timing_argument.expected.txt"
# `//! expect vcd`: a dump that differs from the gold only where IEEE 1364
# 18.2 leaves the writer a choice (codes, $var and change order, `1 ns`, value
# case, an aliased code, a writer's $comment, empty sections and times)
# passes; one value or one time changed fails.
cat > "$T/s/verilog/vcd.gold.vcd" <<'EOF2'
$date today $end $version A 1.0 $end $timescale 1 ns $end
$scope module top $end $var wire 1 ! a $end $var wire 1 ! b $end
$var reg 4 " v [3:0] $end $var integer 32 # i $end $upscope $end
$enddefinitions $end
#0 $dumpvars 0! b1x " b101 # $end
#5 1! bz "
EOF2
cat > "$T/s/verilog/vcd_canonical.file" <<'EOF2'
$version B 2.0 $end $timescale 1ns $end
$scope module top $end $var integer 32 % i [31:0] $end $var reg 4 & v [3:0] $end
$var wire 1 ' b $end $var wire 1 ( a $end $upscope $end $scope module top $end $upscope $end
$enddefinitions $end $comment from the writer $end $dumpall $end
#0 $dumpvars B1X & b101 % 0( 0' $end
#5 1' BZ & 1(
#9
EOF2
sed 's/#5 1!/#5 0!/' "$T/s/verilog/vcd.gold.vcd" > "$T/s/verilog/vcd_value.file"
sed 's/#5/#6/' "$T/s/verilog/vcd.gold.vcd" > "$T/s/verilog/vcd_time.file"
for c in vcd_canonical vcd_value vcd_time; do
    printf '//! expect vcd out.txt == vcd.gold.vcd\nmodule %s; endmodule\n' $c > "$T/s/verilog/$c.v"
done
# A SPICE deck is `netlist` wherever it is filed (no command here: SKIP).
printf '* deck\n.end\n' > "$T/s/verilog-a/deck.sp"
printf '{}\n' > "$T/s/verilog-a/deck.expected.json"
# An upstream-style suite driven by a manifest: its own gold, its own filter.
mkdir -p "$T/up/t" "$T/up/gold"
printf 'module a; endmodule\n' > "$T/up/t/a.v"
cp "$T/up/t/a.v" "$T/up/t/b.v"; cp "$T/up/t/a.v" "$T/up/t/c.v"; cp "$T/up/t/a.v" "$T/up/t/d.v"
printf 'banner 1.0\nvalue 3\n' > "$T/up/t/a.out"; printf 'banner 2.0\nvalue 3\n' > "$T/up/gold/a.gold"
printf 'value 4\n' > "$T/up/t/b.out"; printf 'value 3\n' > "$T/up/gold/b.gold"
printf 'all\n PASSED\n' > "$T/up/t/c.out"
printf 'FAILED\n' > "$T/up/t/d.out"
# e: a row's STD= reaches the tool. f: a compile row's run is told it only compiles.
cp "$T/up/t/a.v" "$T/up/t/e.v"; printf 'std=1364-2005\n' > "$T/up/gold/e.gold"
cp "$T/up/t/a.v" "$T/up/t/f.v"; echo 1 > "$T/up/t/f.exit"
# g: a KEY=VALUE in the gold column is a broken row, not a gold file.
cp "$T/up/t/a.v" "$T/up/t/g.v"
# j, k: STDERR= is text the run's stderr must hold, here a reject-run's diagnostic.
cp "$T/up/t/a.v" "$T/up/t/j.v"; printf 'error: budget\n' > "$T/up/t/j.err"; echo 1 > "$T/up/t/j.exit"
cp "$T/up/t/j.v" "$T/up/t/k.v"; cp "$T/up/t/j.err" "$T/up/t/k.err"; echo 1 > "$T/up/t/k.exit"
# h, i: DIFF= judges the file the run writes (tokens, as a VCD).
cp "$T/up/t/a.v" "$T/up/t/h.v"; printf 'x 1\n' > "$T/up/t/h.file"; printf 'x  1\n' > "$T/up/gold/h.gold"
cp "$T/up/t/a.v" "$T/up/t/i.v"; printf 'x 2\n' > "$T/up/t/i.file"; cp "$T/up/gold/h.gold" "$T/up/gold/i.gold"
cat > "$T/s/up.manifest" <<'EOF2'
#root ../up
verilog	ok	t/a.v	gold/a.gold	FILTER=grep -v banner
verilog	ok	t/b.v	gold/b.gold	FILTER=grep -v banner
verilog	passed	t/c.v
verilog	passed	t/d.v
verilog	ok	t/e.v	gold/e.gold	STD=1364-2005
verilog	compile	t/f.v
verilog	compile	t/g.v	STD=1364-2005
verilog	ok	t/h.v	-	DIFF=out.txt:gold/h.gold
verilog	ok	t/i.v	-	DIFF=out.txt:gold/i.gold
verilog	reject-run	t/j.v	-	STDERR=error: budget
verilog	reject-run	t/k.v	-	STDERR=error: other
EOF2
printf 'verilog-a/xfail.va  # a known bug\nverilog-a/xpass.va\n' > "$T/xfail"

"$CONFORM" -t "$T/tool.conf" -x "$T/xfail" -T 2 -M 128 -j 4 -o "$T/got.tsv" "$T/s" > /dev/null && exit_status=0 || exit_status=$?
"$CONFORM" -t "$T/compile-only.conf" -o "$T/compile.tsv" "$T/s/verilog-a/pass.va" "$T/s/verilog-a/reject_ok.va" > /dev/null || true

cut -f1,2 "$T/got.tsv" "$T/compile.tsv" | cat | sort > "$T/got"
sort > "$T/want" <<'EOF'
PASS	verilog-a/pass.va
FAIL	verilog-a/wrong_want.va
FAIL	verilog-a/checks_off_by_one.va
FAIL	verilog-a/no_assertion_ran.va
FAIL	verilog-a/run_failed.va
PASS	verilog-a/reject_ok.va
FAIL	verilog-a/reject_accepted.va
FAIL	verilog-a/reject_crash.va
PASS	verilog-a/reject_run_ok.va
PASS	verilog-a/exit_code.va
PASS	verilog-a/exit_any.va
PASS	verilog-a/diagnostic.va
FAIL	verilog-a/diagnostic_silent.va
FAIL	verilog-a/exit_any_crash.va
FAIL	verilog-a/exit_any_wrong_output.va
PASS	verilog-a/stdout_line.va
FAIL	verilog-a/timeout.va
XFAIL	verilog-a/xfail.va
XPASS	verilog-a/xpass.va
SKIP	verilog-a/tool_cannot.va
FAIL	verilog-a/reject_out_of_memory.va
PASS	verilog-a/big_reservation.va
SKIP	spice/no_command.va
PASS	verilog/golden.v
PASS	verilog/app.v
PASS	verilog/app.c
FAIL	verilog/golden_diff.v
PASS	up/t/a.v
FAIL	up/t/b.v
PASS	up/t/c.v
FAIL	up/t/d.v
PASS	up/t/e.v
PASS	up/t/f.v
FAIL	up/t/g.v
PASS	up/t/h.v
FAIL	up/t/i.v
PASS	up/t/j.v
FAIL	up/t/k.v
PASS	verilog/named_gold.v
PASS	verilog/keys.v
PASS	verilog/negative_timing.v
FAIL	verilog/negative_timing_argument.v
FAIL	verilog/named_gold_missing.v
PASS	verilog/vcd_canonical.v
FAIL	verilog/vcd_value.v
FAIL	verilog/vcd_time.v
SKIP	verilog-a/deck.sp
PASS	verilog-a/pass.va
FAIL	verilog-a/reject_ok.va
EOF
diff "$T/want" "$T/got"
[ "$exit_status" = 1 ] || { echo "conform exited $exit_status, want 1"; exit 1; }
grep -q 'reject_out_of_memory.va	[0-9]*	run exceeded 128 MiB resident' "$T/got.tsv" || { echo "out of memory not reported"; exit 1; }
grep -q 'compile-only' "$T/compile.tsv" || { echo "compile-only pass not labelled"; exit 1; }
echo "selftest: ok"
