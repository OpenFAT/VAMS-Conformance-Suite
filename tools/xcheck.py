#!/usr/bin/env python3
"""Confirm tests/netlist/ oracles against Xyce, a simulator this suite does
not judge, so that an oracle taken from ngspice is not ngspice judged against
itself.

    python3 tools/xcheck.py [-j 4] [-o results.jsonl] [ORACLE.expected.json ...]
    python3 tools/xcheck.py --write results.jsonl  # record "confirmed" fields

With no oracles named, it takes every tests/netlist/ oracle whose kind names
ngspice. Each oracle plot (operating point, DC, transient, AC, noise
spectrum) becomes one Xyce run of the deck, translated to Xyce's dialect,
with a `.print` of the oracle's own columns. A column scores
max |xyce - want| / (atol + rtol*|want|) over its values, in units of the
oracle's tolerance: <= 1 confirms it. Transient columns are reported at the
oracle's own times (`outputtimepoints`), from a run at reltol 1e-6 (the
converged answer, which an oracle at ngspice's default reltol must already
be within tolerance of).

A deck Xyce cannot run (a device, analysis or option only ngspice has)
reports why; nothing is guessed. Xyce runs under `systemd-run --user` with
MemoryMax=2G. XYCE names the executable.
"""
import argparse, glob, json, math, os, re, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rawcheck  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NETLIST = os.path.join(ROOT, "tests", "netlist")
XYCE = os.environ.get("XYCE", "Xyce")


class Unsupported(Exception):
    pass


# ngspice model level -> Xyce level, per model type; a level missing here has
# no Xyce twin with the same equations.
LEVELS = {
    "nmos": {"1": "1", "2": "2", "3": "3", "8": "9", "49": "9", "14": "14", "54": "14"},
    "npn": {"1": "1"},
    "d": {"1": "1"},
    "njf": {"1": "1"},
}
LEVELS["pmos"] = LEVELS["nmos"]
LEVELS["pnp"] = LEVELS["npn"]
LEVELS["pjf"] = LEVELS["njf"]
# Element letters Xyce reads with ngspice's meaning.
ELEMENTS = set("rclkvieghfdqjmxbt")
DROPPED = {".print", ".plot", ".width", ".save", ".probe", ".end", ".title", ".option", ".options", ".opt", ".temp", ".meas", ".measure"}
PASSED = {".model", ".param", ".subckt", ".ends", ".include", ".inc", ".lib", ".endl", ".ic", ".nodeset", ".func", ".global", ".csparam"}
# Options that only steer the numerics; Xyce runs at its own tight ones.
NUMERIC = {"reltol", "abstol", "vntol", "chgtol", "trtol", "method", "maxord", "xmu", "delmax", "lvlcod", "noacct", "acct",
           "nopage", "itl1", "itl2", "itl4", "itl5", "gminsteps", "srcsteps", "pivtol", "pivrel", "interp", "post", "keepopinfo"}
ANALYSES = {".op", ".dc", ".tran", ".ac", ".noise"}
PLOTS = {"operating point": ".op", "dc transfer characteristic": ".dc", "transient analysis": ".tran",
         "ac analysis": ".ac", "noise spectral density curves": ".noise"}


def logical_lines(text):
    """Cards after the title line, continuations joined, comments removed."""
    out = []
    for raw in text.splitlines()[1:]:
        line = re.split(r"\s;|^;|\s\$\s", raw)[0].rstrip()
        if not line.strip() or line.lstrip().startswith("*"):
            continue
        if line.lstrip().startswith("+") and out:
            out[-1] += " " + line.lstrip()[1:]
        else:
            out.append(line.strip())
    return out


def braced(v):
    v = v.strip()
    if v.startswith("{") or re.fullmatch(r"[-+]?[\d.]+(e[-+]?\d+)?[a-z]*", v, re.I):
        return v
    return "{" + v.strip("'\"") + "}"


def translate_model(card):
    m = re.match(r"\.model\s+(\S+)\s+(\w+)\s*\(?(.*?)\)?\s*$", card, re.I)
    if not m:
        raise Unsupported(f"model card: {card[:60]}")
    name, typ, params = m.group(1), m.group(2).lower(), m.group(3)
    if typ in ("r", "c", "l", "sw", "csw"):
        if typ in ("sw", "csw"):
            raise Unsupported("switch model (Xyce's switch is a smooth transition, ngspice's an abrupt one with hysteresis)")
        return card
    if typ not in LEVELS:
        raise Unsupported(f"model type {typ}")
    lv = re.search(r"\blevel\s*=\s*([\w.]+)", params, re.I)
    level = lv.group(1).rstrip(".0") if lv and "." in lv.group(1) else (lv.group(1) if lv else "1")
    if level not in LEVELS[typ]:
        raise Unsupported(f"{typ} level {level}")
    if lv:
        params = params[:lv.start()] + f"level={LEVELS[typ][level]}" + params[lv.end():]
    params = re.sub(r"\b(tnom|tref)\s*=\s*(\S+)", lambda t: f"{t.group(1)}={kelvin(number(t.group(2)))}", params, flags=re.I)
    return f".model {name} {typ} ({params})"


def translate(text):
    """(body cards, options dict, analysis cards {kind: card}, measure cards)."""
    lines = logical_lines(text)
    body, opts, analyses, meas = [], {}, {}, []
    in_control = False
    for card in lines:
        low = card.lower()
        head = low.split()[0]
        if head == ".control":
            in_control = True
            continue
        if head == ".endc":
            in_control = False
            continue
        if in_control:
            if re.match(r"(run|op|dc|tran|ac|noise|alter|set|let|reset|alterparam)\b", low):
                raise Unsupported(f"control block runs `{low[:40]}`")
            continue
        if head in (".option", ".options", ".opt"):
            for k, v in re.findall(r"(\w+)\s*=\s*(\S+)", card):
                opts[k.lower()] = v
            words = set(re.sub(r"\w+\s*=\s*\S+", "", card[len(head):]).lower().split())
            other = (set(opts) | words) - NUMERIC - {"temp", "tnom", "gmin"}
            if other:
                raise Unsupported(f"option {', '.join(sorted(other))}")
            continue
        if head == ".temp":
            vals = card.split()[1:]
            if len(vals) != 1:
                raise Unsupported(".temp with several values")
            opts["temp"] = vals[0]
            continue
        if head in (".meas", ".measure"):
            meas.append(card)
            continue
        if head == ".dc" and re.match(r"\.dc\s+temp\b", low):
            f = card.split()
            if len(f) != 5:
                raise Unsupported(".dc temp with a second sweep")
            card = f".dc temp {kelvin(number(f[2]))} {kelvin(number(f[3]))} {float(number(f[4])) * KQ:.12g}"
        if head in ANALYSES:
            if head in analyses:
                raise Unsupported(f"two {head} cards")
            analyses[head] = card
            continue
        if head in DROPPED:
            continue
        if head.startswith("."):
            if head not in PASSED:
                raise Unsupported(f"card {head}")
            if head == ".model":
                card = translate_model(card)
            elif head == ".param":
                card = ".param " + " ".join(f"{k}={braced(v)}" for k, v in re.findall(r"(\w+)\s*=\s*('[^']*'|\{[^}]*\}|\S+)", card[6:]))
            body.append(card)
            continue
        if head[0] not in ELEMENTS:
            raise Unsupported(f"element {card.split()[0]}")
        card = re.sub(r"\b(d?temp)\s*=\s*(\S+)", lambda t: f"{t.group(1)}=" + (kelvin(number(t.group(2))) if t.group(1).lower() == "temp"
                      else f"{float(number(t.group(2))) * KQ:.12g}"), card, flags=re.I)
        if head[0] == "b":
            card = re.sub(r"\b([vi])\s*=\s*(.+)$", lambda m: f"{m.group(1)}={braced(m.group(2))}", card, flags=re.I)
        body.append(card)
    if not analyses:
        raise Unsupported("no analysis card")
    return body, opts, analyses, meas


# Xyce keeps SPICE3's k and q (k/q = 8.617087e-5 V/K), ngspice CODATA 2014's
# (8.617330e-5): at one temperature their thermal voltages differ by 2.8e-5,
# 7e-4 in exp(0.7 V/Vt). Scaling every absolute temperature Xyce sees by
# this ratio gives it ngspice's kT/q and leaves T/Tnom as it was.
KQ = (1.38064852e-23 / 1.6021766208e-19) / (1.3806226e-23 / 1.6021918e-19)

QN = 1.6021766208e-19 / 1.6021918e-19


def kelvin(celsius):
    return f"{(float(celsius) + 273.15) * KQ - 273.15:.12g}"


def number(v):
    m = re.fullmatch(r"([-+]?[\d.]+(?:e[-+]?\d+)?)", v.strip("{}"), re.I)
    if not m:
        raise Unsupported(f"temperature {v} is not a number")
    return m.group(1)


def options(opts, kind):
    dev = {"temp": kelvin(number(opts.get("temp", "27"))), "tnom": kelvin(number(opts.get("tnom", "27")))}
    if "gmin" in opts:
        dev["gmin"] = opts["gmin"]
    out = [".options device " + " ".join(f"{k}={v}" for k, v in dev.items())]
    out.append(".options nonlin reltol=1e-7 abstol=1e-15")
    if kind == ".tran":
        out += [".options timeint reltol=1e-6 abstol=1e-15", ".options nonlin-tran reltol=1e-7 abstol=1e-15"]
    return out


def xexpr(name, kind):
    """The Xyce .print expression for an oracle column, or None."""
    n = rawcheck.canonical(name)
    if kind == ".noise":
        return {"onoise_spectrum": "ONOISE", "inoise_spectrum": "INOISE"}.get(n)
    m = re.fullmatch(r"v\(([^,()]+)(?:,([^,()]+))?\)", n)
    if m:
        nodes = [x.replace(".", ":").upper() for x in m.groups() if x]
        return f"V({','.join(nodes)})"
    m = re.fullmatch(r"i\(([^()]+)\)", n) or re.fullmatch(r"([a-z][^()@\[\]]*)", n)
    if m and m.group(1)[0] in "veh l".replace(" ", ""):
        return f"I({m.group(1).replace('.', ':').upper()})"
    return None


def run_xyce(deck, srcdir, work):
    for f in os.listdir(srcdir):
        dst = os.path.join(work, f)
        if not os.path.exists(dst):
            os.symlink(os.path.join(srcdir, f), dst)
    path = os.path.join(work, "x.cir")
    with open(path, "w") as fh:
        fh.write(deck)
    cmd = ["systemd-run", "--user", "--scope", "-q", "-p", "MemoryMax=2G", "-p", "MemorySwapMax=0",
           "env", "OPENBLAS_NUM_THREADS=1", XYCE, "x.cir"]
    try:
        p = subprocess.run(cmd, cwd=work, capture_output=True, text=True, errors="replace", timeout=300)
    except subprocess.TimeoutExpired:
        return 124, "timeout"
    return p.returncode, p.stdout + p.stderr


def read_csv(path):
    rows = [l.strip().split(",") for l in open(path) if l.strip()]
    return [c.strip('" ') for c in rows[0]], [[float(x) for x in r] for r in rows[1:]]


def score(got, want, rtol, atol):
    w = rawcheck.scalar(want)
    err = abs(got - w)
    return err / (atol + rtol * abs(w)), (err / abs(w) if w else (0.0 if err == 0 else math.inf))


def interp(xs, ys, t):
    if t <= xs[0]:
        return ys[0]
    if t >= xs[-1]:
        return ys[-1]
    lo, hi = 0, len(xs) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if xs[mid] <= t else (lo, mid)
    f = (t - xs[lo]) / (xs[hi] - xs[lo]) if xs[hi] != xs[lo] else 0
    return ys[lo] + f * (ys[hi] - ys[lo])


def check_plot(want, body, opts, analyses, srcdir, title):
    kind = PLOTS.get(want["name"].lower())
    if kind is None:
        raise Unsupported(f"plot {want['name']}")
    if kind not in analyses:
        if kind == ".op" and ".op" not in analyses:
            analyses = dict(analyses, **{".op": ".op"})
        else:
            raise Unsupported(f"plot {want['name']} without its card")
    axis = want.get("axis")
    exprs = {}
    for name in want["columns"]:
        e = xexpr(name, kind)
        if e:
            exprs[name] = e
    if not exprs:
        raise Unsupported(f"no column of {want['name']} has an Xyce name")
    ptype = {".op": "dc"}.get(kind, kind[1:])
    noise = kind == ".noise"
    out = "o.csv" if noise else "o.raw"
    # Xyce reports at the oracle's own times rather than between its steps,
    # where linear interpolation across a corner reads a value that is not there.
    times = [f".options output outputtimepoints={','.join(repr(t) for t in axis['values'])}"] if kind == ".tran" and axis else []
    deck = [title] + body + options(opts, kind) + times + [analyses[kind],
            f".print {ptype} format={'csv' if noise else 'raw'} file={out} " + " ".join(exprs.values()), ".end", ""]
    with tempfile.TemporaryDirectory(dir=os.environ.get("XCHECK_TMP")) as work:
        rc, log = run_xyce("\n".join(deck), srcdir, work)
        outp = os.path.join(work, out)
        if rc != 0 or not os.path.exists(outp):
            err = [l for l in log.splitlines() if "error" in l.lower()] or log.strip().splitlines()[-3:]
            raise RuntimeError(f"xyce exit {rc}: {' | '.join(err[:3])[:300]}")
        if noise:
            hdr, rows = read_csv(outp)
            # Xyce's 4kT and 2qI, at ngspice's kT/q, are q_x/q_n high (flicker noise is not).
            table = [[complex(math.sqrt(v * QN) if i else v, 0) for i, v in enumerate(r)] for r in rows]
            names = hdr
        else:
            p = rawcheck.parse_raw(open(outp, "rb").read())[0]
            names, table = p[1], p[4]
    cols, vals = {}, {}
    rows = want.get("row_indices") if want["match"] == "selected_rows" else None
    xs = [r[0].real for r in table]
    if want["match"] == "unordered":
        raise Unsupported("unordered rows")
    for name, e in exprs.items():
        c = 1 + list(exprs).index(name)
        worst, vals[name] = (0.0, 0.0), []
        for j, v in enumerate(want["columns"][name]["values"]):
            if kind in (".tran", ".ac", ".noise") and axis:
                got = interp(xs, [r[c] for r in table], axis["values"][j])
            else:
                r = rows[j] if rows else j
                if want.get("row_count") is not None and len(table) != want["row_count"]:
                    raise RuntimeError(f"xyce wrote {len(table)} rows, the oracle {want['row_count']}")
                got = table[r][c]
            col = want["columns"][name]
            if col.get("magnitude"):
                got, v = complex(abs(got), 0), abs(rawcheck.scalar(v))
            s = score(got, v, col["rtol"], col["atol"])
            worst = max(worst, s)
            vals[name].append([got.real, got.imag])
        cols[name] = worst
    return cols, [n for n in want["columns"] if n not in exprs], vals


def check(path):
    oracle = json.load(open(path))
    stem = path[: -len(".expected.json")]
    decks = [stem + e for e in (".sp", ".cir") if os.path.exists(stem + e)]
    res = {"oracle": os.path.relpath(path, ROOT), "kind": oracle["oracle"]["kind"]}
    try:
        if not decks:
            raise Unsupported("no deck")
        if oracle["expect"]["status"] == "error":
            raise Unsupported("status error: a refusal, not a value")
        text = open(decks[0], errors="replace").read()
        body, opts, analyses, meas = translate(text)
        title = "* " + text.splitlines()[0]
        cols, unmapped, values = {}, [], {}
        for want in oracle["expect"].get("plots", []):
            try:
                c, u, v = check_plot(want, body, opts, analyses, os.path.dirname(decks[0]), title)
                cols.update({f"{want['name']}:{k}": x for k, x in c.items()})
                values.update({f"{want['name']}:{k}": x for k, x in v.items()})
                unmapped += [f"{want['name']}:{n}" for n in u]
            except Unsupported as e:
                unmapped.append(f"{want['name']}: {e}")
        checks = [c["kind"] + (":" + c.get("name", "") if c.get("name") else "") for c in oracle["expect"].get("checks", [])]
        unmapped += [f"check {c}" for c in checks]
        if not cols:
            raise Unsupported("; ".join(unmapped))
        ratio = max(v[0] for v in cols.values())
        res.update(status="confirmed" if ratio <= 1 else "disagree", max_ratio=ratio,
                   max_rel_err=max(v[1] for v in cols.values()), columns=cols, unconfirmed=unmapped, values=values)
    except Unsupported as e:
        res.update(status="unsupported", reason=str(e))
    except (RuntimeError, ValueError, KeyError, IndexError, OSError) as e:
        res.update(status="error", reason=f"{type(e).__name__}: {e}")
    return res


def xyce_version():
    p = subprocess.run([XYCE, "-v"], capture_output=True, text=True)
    return p.stdout.strip().split("\n")[-1]


def results(path):
    """The JSON lines a run wrote, the last line per oracle."""
    if not os.path.exists(path):
        return {}
    return {r["oracle"]: r for r in map(json.loads, open(path))}


def write(path):
    version = xyce_version()
    for r in results(path).values():
        if r["status"] != "confirmed":
            continue
        dst = os.path.join(ROOT, r["oracle"])
        text = open(dst).read()
        d = json.loads(text)
        d["oracle"]["confirmed"] = {"tool": "xyce", "version": version, "command": "python3 tools/xcheck.py " + r["oracle"],
                                    "max_rel_err": float(f"{r['max_rel_err']:.3g}"),
                                    "max_tolerance_ratio": float(f"{r['max_ratio']:.3g}")}
        if r["unconfirmed"]:
            d["oracle"]["confirmed"]["unconfirmed"] = r["unconfirmed"]
        indent = len(re.match(r"\{\n( *)", text).group(1)) or 1
        with open(dst, "w") as fh:
            json.dump(d, fh, indent=indent)
            fh.write("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("oracles", nargs="*")
    ap.add_argument("-j", type=int, default=4)
    ap.add_argument("-o", default="xcheck.jsonl", help="JSON lines, appended; oracles already in it are not rerun")
    ap.add_argument("--write")
    a = ap.parse_args()
    if a.write:
        return write(a.write)
    paths = a.oracles or sorted(p for p in glob.glob(os.path.join(NETLIST, "**", "*.expected.json"), recursive=True)
                                if "ngspice" in json.load(open(p))["oracle"]["kind"])
    done = results(a.o)
    todo = [os.path.abspath(p) for p in paths if os.path.relpath(os.path.abspath(p), ROOT) not in done]
    with ThreadPoolExecutor(a.j) as pool, open(a.o, "a") as out:
        for r in pool.map(check, todo):
            out.write(json.dumps(r) + "\n")
            out.flush()
            print(r["status"], r["oracle"], f"{r['max_ratio']:.3g}" if "max_ratio" in r else r.get("reason", ""), flush=True)
    res = results(a.o)
    print({s: sum(r["status"] == s for r in res.values()) for s in ("confirmed", "disagree", "unsupported", "error")})


if __name__ == "__main__":
    main()
