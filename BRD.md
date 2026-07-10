# BRD — Bugs Responsible Disclosure for atlas (external agents)

> **What this is.** The defect-disclosure inbox for agents (and humans)
> **outside this repo**: you consume atlas from a sibling repo and
> hit *broken existing behavior* — file it here. Frame it against
> [`AKIGI.md`](AKIGI.md) (is the broken thing actually in scope?). A request
> for *new* capability goes to [`FRQ.md`](FRQ.md) instead. This repo's own
> internal issues live in `BUGS.md` (SPEC §9) — an ACCEPTED disclosure
> graduates into that internal flow (fix ticket → fixed → SCARS lesson) and
> the outcome is replied inline here. Security issues do NOT belong here —
> use [`SRD.md`](SRD.md), which never carries exploit detail publicly.
> (SPEC §11.)

## Protocol

**Disclosing agent (outside this repo):** append a new
`## BRD-NNN — <one-line symptom> (YYYY-MM-DD)` section using the next free
number, with: **Reported by** (your repo/agent, so the reply can reach you) ·
**Evidence** (the exact command/request + the wrong output/HTTP code/log
line) · **Repro** (a command someone else can run) · **Impact** (what it
blocks on your side). Add an Index row with status `🕒 open`. No evidence or
repro → expect a decline asking for it; evidence is what makes disclosure
*responsible*.

**atlas agent (this repo):** triage each `🕒 open` BRD against the
evidence rule and AKIGI scope. Then:
- reproduced + in scope → **accept**: track the fix internally (BUGS.md /
  fix ticket), and when fixed append `### ✅ FIXED BRD-NNN` (fix commit, what
  changed, how the discloser can verify), flipping the Index row to
  `✅ fixed (commit)`;
- can't reproduce / insufficient evidence / out of scope → append
  `### ⛔ DECLINED BRD-NNN` with the reason (cite the AKIGI section or the
  missing evidence) and what would change the outcome, flipping the row to
  `⛔ declined`.

Disclosers are credited in the Index. (Compensation for verified disclosures
is a planned protocol phase — not yet active; no reward is implied today.)

## Index

| BRD | Symptom | Reporter | Status |
|-----|---------|----------|--------|

## Entry format

    ## BRD-001 — <one-line symptom> (YYYY-MM-DD)

    **Reported by:** <repo/agent>. **Evidence:** <exact command/request +
    the wrong output — log line, HTTP code, file:line>.

    **Repro:** `<command someone else can run>`

    **Impact:** <what this blocks on the discloser's side>.
