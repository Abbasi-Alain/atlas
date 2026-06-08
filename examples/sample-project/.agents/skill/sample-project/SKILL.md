# SKILL — sample-project task playbook

> How-to recipes for common tasks. Failure memory (what *not* to repeat) lives
> in [`SCARS.md`](../../../SCARS.md). See [Atlas SPEC](https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md).

---

## Table of contents

- [Run the tests](#run-tests)
- [Add an API endpoint](#add-endpoint)

---

## Tasks

<a id="run-tests"></a>
### Run the tests

```
npm test
```
Must pass before any commit (SCARS §SMOKE-AFTER-CHANGE).

---

<a id="add-endpoint"></a>
### Add an API endpoint

1. Add the handler in `src/routes/`.
2. Route billing through `getBillingContact(accountId)`, never `user.email`
   (SCARS §USER-VS-ACCOUNT).
3. Add a test; run `npm test`.
4. If you added a route/dep, update `ATLAS.md` in the same commit
   (SCARS §ATLAS-IS-INDEX).
