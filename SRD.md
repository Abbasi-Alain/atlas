# SRD — Security Responsible Disclosure for atlas (external agents)

> **What this is.** The security-disclosure surface for agents (and humans)
> **outside this repo**. Responsible disclosure means the PUBLIC entry here
> carries only minimal metadata — **never** exploit details, proof-of-concept
> code, or anything that helps an attacker before a fix ships. Full detail
> goes through the private channel below. Unlike [`FRQ.md`](FRQ.md) and
> [`BRD.md`](BRD.md), SRD entries are **never auto-triaged by an agent**:
> the maintainer is always escalated (AKIGI escalation line). (SPEC §11.)

## Private channel

**Send full details here, not in this file:**
GitHub private vulnerability reporting for this repo —
`https://github.com/Abbasi-Alain/atlas/security/advisories/new`

## Protocol

**Disclosing agent (outside this repo):**
1. Send the full report (affected code, reproduction, impact, suggested fix)
   through the **private channel** above.
2. Append here ONLY a minimal public marker:
   `## SRD-NNN — <affected surface, no detail> (YYYY-MM-DD)` with
   **Reported by** (repo/agent or handle) · **Severity class**
   (low/med/high/critical, your estimate) · one line naming the affected
   surface (e.g. "the install script's download step") — nothing an attacker
   can act on. Add an Index row with status `🕒 reported`.

**atlas maintainer (a human — agents acknowledge but never
dispose):** confirm receipt on the private channel, triage, fix privately,
then after the fix ships append `### ✅ FIXED SRD-NNN` (fix commit/release,
now-safe summary) and flip the Index row to `✅ fixed (commit)`. Invalid or
not-a-vulnerability → `### ⛔ INVALID SRD-NNN` with the reason, row
`⛔ invalid`.

Disclosers are credited in the Index. (Compensation for verified disclosures
is a planned protocol phase — not yet active; no reward is implied today.)

## Index

| SRD | Affected surface | Reporter | Severity | Status |
|-----|------------------|----------|----------|--------|

## Entry format

    ## SRD-001 — <affected surface, no exploit detail> (YYYY-MM-DD)

    **Reported by:** <repo/agent or handle>. **Severity class:** <low|med|
    high|critical>. Full report sent via the private channel on <date>.
