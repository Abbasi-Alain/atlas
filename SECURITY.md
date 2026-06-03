# Security Policy

## Supported versions

| Version | Status |
|---|---|
| `0.1.x` | ✅ Receives security fixes |
| < 0.1.0 | — (no previous versions exist) |

## Reporting a vulnerability

**Do not file public GitHub issues for security problems.**

Two private channels:

1. **GitHub private advisory** *(preferred)* — https://github.com/Abbasi-Alain/atlas/security/advisories/new
   GitHub coordinates disclosure and assigns a CVE if appropriate.

2. **Email** — `abbasi.alain (at) gmail (dot) com` with subject `[atlas-security]`.

Please include:

- ATLAS version (`atlas version`)
- OS + shell
- Reproduction steps
- Impact (what an attacker can do)

## Response timeline

- **Acknowledgment**: within 72 hours.
- **Triage**: within 7 days.
- **Fix or disclosure plan**: within 30 days for actively-exploited issues; within 90 days otherwise.

## Scope

In scope:

- `bin/atlas` — the CLI itself.
- `install.sh` and `bin/atlas-node` — installers and wrappers.
- `adapters/*/install.sh` — runtime wiring scripts.
- Default templates that get rendered into user projects.

Out of scope (these are user code, not ATLAS):

- Anything the user writes into their generated `ATLAS.md` / `SKILL.md` / `CLAUDE.md`.
- Vulnerabilities in third-party CLIs ATLAS shells out to (`git`, `gh`, `glab`, `codex`, `claude`).

## Past advisories

None yet.
