#!/usr/bin/env python3
"""How much of each standard the tests cover, and how much of it each tool
supports.

    python3 tools/coverage.py                        # rules each language's tests cite
    python3 tools/coverage.py --uncovered vams       # the rules no test cites
    python3 tools/coverage.py --results results verilog-a [--list]

The rules are spec/vams.tsv (the Verilog-AMS LRM's sentences, which also
govern Verilog-A) and spec/ieee1364.tsv (IEEE 1364-2005's headings). A test
cites them with `//! lrm C[:N]` and `//! inherited IEEE 1364-2005 C`
(and their `-reject` forms). A testable rule is one that states something a
test can observe: pol other than 0 for the LRM, a leaf heading other than
non-normative, unspecified or tool-option for 1364.

An LRM sentence `C:N` is covered exactly by a test citing `C:N`, and by
clause by a test citing only `C`. A 1364 heading is covered by a test citing
it or anything under it.

With --results, each tool's results/<tool>.tsv (conform -o) judges every rule
the language's tests cover: supported when all its tests pass, partial when
some do, unsupported when none do. A test the tool skipped or never ran
counts as not passing. --list prints one row per rule.
"""
import argparse, re, sys
from collections import Counter, defaultdict
from pathlib import Path

from report import languages

ROOT = Path(__file__).resolve().parents[1]
LANGS = ["verilog", "verilog-a", "verilog-ams", "spice"]
CITE = re.compile(r"^//! (lrm|inherited)(?:-reject)?(?: IEEE 1364-2005)? (.*)$", re.M)
CLAUSE = re.compile(r"^(?:[0-9]+|[A-H])(?:\.[0-9]+)*(?::[0-9]+)?$")


def rows(path):
    return [l.split("\t") for l in path.read_text().splitlines() if l and not l.startswith("#")]


def citations():
    """test name (path under tests/) -> {"vams": cites, "ieee1364": cites}."""
    out = {}
    for lang in LANGS:
        for f in sorted((ROOT / "tests" / lang).rglob("*")):
            if not f.is_file():
                continue
            cites = {"vams": set(), "ieee1364": set()}
            for kind, rest in CITE.findall(f.read_text(errors="replace")):
                spec = "vams" if kind == "lrm" else "ieee1364"
                cites[spec] |= {t for t in re.split(r"[\s,]+", rest.replace("annex ", "")) if CLAUSE.match(t)}
            if cites["vams"] or cites["ieee1364"]:
                out[str(f.relative_to(ROOT / "tests"))] = cites
    return out


def rules():
    """spec -> [(id, label)] of its testable rules."""
    vams = [(r[0], f"{r[1]}: {r[4]}") for r in rows(ROOT / "spec/vams.tsv") if r[2] != "0"]
    heads = rows(ROOT / "spec/ieee1364.tsv")
    ids = {r[0] for r in heads}
    leaf = [r for r in heads if not any(i.startswith(r[0] + ".") for i in ids)]
    ieee = [(r[0], r[2]) for r in leaf if r[1] not in ("non-normative", "unspecified", "tool-option")]
    return {"vams": vams, "ieee1364": ieee}


def index(cites):
    """spec -> cite -> the tests in `cites` citing it."""
    idx = {"vams": defaultdict(list), "ieee1364": defaultdict(list)}
    for t, c in cites.items():
        for spec, xs in c.items():
            for x in xs:
                idx[spec][x].append(t)
    return idx


def tests_of(spec, rule, idx):
    """(exact, by clause): the tests in `idx` covering `rule`."""
    idx = idx[spec]
    if spec == "vams":
        return idx.get(rule, []), idx.get(rule.split(":")[0], [])
    return sorted({t for x, ts in idx.items() if x == rule or x.startswith((rule + ".", rule + ":")) for t in ts}), []


def results(path):
    """test name -> passed, from conform's -o file."""
    out = {}
    for line in path.read_text().splitlines():
        status, name = line.split("\t")[:2]
        out[name] = status in ("PASS", "XPASS")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("lang", nargs="?", default="verilog-a", choices=LANGS)
    ap.add_argument("--uncovered", choices=["vams", "ieee1364"])
    ap.add_argument("--results", type=Path)
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    cites, specs = citations(), rules()
    idx = index(cites)
    names = {"vams": "Verilog-AMS LRM 2023 sentences", "ieee1364": "IEEE 1364-2005 headings"}

    if a.uncovered:
        for rule, label in specs[a.uncovered]:
            exact, clause = tests_of(a.uncovered, rule, idx)
            if not exact:
                print(f"{rule}\t{'clause-only' if clause else 'none'}\t{label}")
        return

    if not a.results:
        print("| Rules | Tests from | Testable | Cited exactly | Cited by clause only | Uncovered |")
        print("|---|---|---:|---:|---:|---:|")
        for spec, rs in specs.items():
            for lang in LANGS + ["all"]:
                sub = index({t: c for t, c in cites.items() if lang == "all" or t.startswith(lang + "/")})
                n = Counter()
                for rule, _ in rs:
                    exact, clause = tests_of(spec, rule, sub)
                    n["exact" if exact else "clause" if clause else "none"] += 1
                if n["exact"] + n["clause"]:
                    print(f"| {names[spec]} | {lang} | {len(rs)} | {n['exact']} | {n['clause']} | {n['none']} |")
        return

    tools = {p.stem: results(p) for p in sorted(a.results.glob("*.tsv"))}
    sub = index({t: c for t, c in cites.items() if t.startswith(a.lang + "/")})
    tally = defaultdict(Counter)
    if a.list:
        print("rule\ttests\t" + "\t".join(tools))
    for spec, rs in specs.items():
        for rule, _ in rs:
            exact, clause = tests_of(spec, rule, sub)
            ts = exact or clause
            if not ts:
                continue
            passed = {tool: sum(r.get(t, False) for t in ts) for tool, r in tools.items()}
            for tool, p in passed.items():
                tally[(spec, tool)]["supported" if p == len(ts) else "partial" if p else "unsupported"] += 1
            if a.list:
                print(f"{rule}\t{len(ts)}\t" + "\t".join(f"{passed[t]}/{len(ts)}" for t in tools))
    if a.list:
        return
    print(f"Rules the {a.lang} tests cover, judged per tool (supported = every test citing the rule passes).\n")
    print("| Rules | Tool | Covered rules | Supported | Partial | Unsupported | Support |")
    print("|---|---|---:|---:|---:|---:|---:|")
    for (spec, tool), n in sorted(tally.items()):
        total = sum(n.values())
        print(f"| {names[spec]} | {tool} | {total} | {n['supported']} | {n['partial']} | {n['unsupported']} "
              f"| {100 * n['supported'] / total:.1f}% |")
    langs = languages()
    print(f"\n| Tool | {a.lang} tests run | Passed | Failed | Skipped |")
    print("|---|---:|---:|---:|---:|")
    for p in sorted(a.results.glob("*.tsv")):
        rows_ = [line.split("\t") for line in p.read_text().splitlines()]
        s = Counter(r[0] for r in rows_ if (langs.get(r[1]) or r[1].split("/", 1)[0]) == a.lang)
        print(f"| {p.stem} | {sum(s.values())} | {s['PASS'] + s['XPASS']} | {s['FAIL'] + s['XFAIL']} | {s['SKIP']} |")


if __name__ == "__main__":
    sys.exit(main())
