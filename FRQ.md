# FRQ — Feature Request Queue for atlas (cross-agent)

> **What this is.** A shared inbox where agents in **sibling repos** (and
> humans) request features from THIS repo. This repo's own agent reviews each
> request, decides against [`AKIGI.md`](AKIGI.md)'s acceptance principles, and
> replies inline — so the requester learns the outcome and exactly how to use
> what shipped. A request is a *new capability*; *broken existing behavior*
> is a bug report, not an FRQ. (SPEC §11.)

## Protocol

**Requesting agent (outside this repo):** read [`AKIGI.md`](AKIGI.md) FIRST
and frame your ask against its Purpose and Scope — requests touching a
Non-goal will be declined. Then append a new
`## FRQ-NNN — <title> (YYYY-MM-DD)` section using the next free number, with
three parts: **Requested by** (your repo/agent, so the reply can reach you) ·
**Why** (the concrete blocker: what fails today, with evidence) · **Ask**
(the specific capability + the exact fields/shape you need). Add a row to
the Index below with status `🕒 open`.

**atlas agent (this repo):** review each `🕒 open` FRQ against
AKIGI's acceptance principles. Then:
- worthwhile → **implement**, append a `### ✅ RESOLVED FRQ-NNN` subsection
  (the concrete surface: endpoint/command, request/response shape, errors,
  auth, how-to-wire), set the Index row to `✅ resolved (commit)`;
- not now / out of scope → append `### ⛔ DECLINED FRQ-NNN` with the reason
  (cite the AKIGI section) + the recommended alternative, set the row to
  `⛔ declined`.

Keep answers concrete (commands/JSON over prose). If a shipped FRQ later
breaks, that's a bug report referencing the FRQ — not a new FRQ. If a
shipped FRQ's contract must change, append a dated **⚠ BREAKING** note to
its RESOLVED subsection so the requester's agent finds it on the next read.

## Index

| FRQ | Title | Requester | Status |
|-----|-------|-----------|--------|

## Entry format

    ## FRQ-001 — <one-line title> (YYYY-MM-DD)

    **Requested by:** <repo/agent>. **Why:** <the concrete blocker, with
    evidence — what fails today and where>.

    **Ask:** <the specific capability + the exact fields/shape you need,
    e.g. "expose POST /api/thing taking {a, b} returning {c, d}">.
