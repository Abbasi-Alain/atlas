# SKILL — sample-project error/pattern playbook

> Minimal example. Real projects accrete anchors over time. See [Atlas SPEC](https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md).

---

## Table of contents

**Process / hygiene**
- [§NO-COAUTHOR — never add AI-assistant attribution to commits](#no-coauthor)
- [§ATLAS-IS-INDEX — update ATLAS.md when structure changes](#atlas-is-index)
- [§SMOKE-AFTER-CHANGE — run the smoke set after touching runtime](#smoke-after-change)

**Domain-specific**
- [§USER-VS-ACCOUNT — User ≠ Account, never conflate](#user-vs-account)

---

## Process / hygiene

<a id="no-coauthor"></a>
### §NO-COAUTHOR — never add AI-assistant attribution to commits
Do not add `Co-Authored-By: Claude …` or equivalent.

---

<a id="atlas-is-index"></a>
### §ATLAS-IS-INDEX — update ATLAS.md when structure changes
Structural changes (new route, new external dep, new service) update ATLAS in the same commit.

---

<a id="smoke-after-change"></a>
### §SMOKE-AFTER-CHANGE — run the smoke set after touching runtime
`npm test` must pass before commit.

---

## Domain-specific

<a id="user-vs-account"></a>
### §USER-VS-ACCOUNT — User ≠ Account, never conflate

**Symptom.** Billing emails sent to the wrong address; permissions surfaces show "no access" for legitimate users.

**Root cause.** A `User` is one human; an `Account` is the billing entity. One Account may have many Users (and one User may belong to many Accounts via teams). Code that assumes `user.email` is the billing email will silently misroute.

**Do NOT.**
- Use `user.email` for invoicing.
- Use `account.email` for OAuth login flows.

**Do.** Always route through `getBillingContact(accountId)` / `getLoginEmail(userId)`.

**Where.** `src/billing.ts::getBillingContact`, `src/auth.ts::getLoginEmail`.

**Shipped in.** `abcd123`.

---

## Appendix — commit-anchor index

| SHA | Anchor |
|---|---|
| abcd123 | §USER-VS-ACCOUNT |
