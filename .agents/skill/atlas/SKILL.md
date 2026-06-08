# SKILL — atlas task playbook

> **The "how do I do X here" file.** Common atlas tasks as recipes. Failure
> knowledge lives in [`/SCARS.md`](../../../SCARS.md) (cite its `§ANCHORS`).
>
> **Reading order.** [`ATLAS.md`](../../../ATLAS.md) (*where*) →
> [`SCARS.md`](../../../SCARS.md) (*what breaks*) → **this file** (*how*).

---

## Table of contents

- [Run the smoke set](#run-smoke)
- [Add a CLI command](#add-command)
- [Add a runtime adapter](#add-adapter)
- [Add a package channel](#add-channel)
- [Cut a release](#cut-release)

---

## Tasks

<a id="run-smoke"></a>
### Run the smoke set

```
shellcheck bin/atlas && bash tests/bootstrap.test.sh && (cd examples/sample-project && ../../bin/atlas check)
```
Must be green before any commit (SCARS §SMOKE-AFTER-CHANGE).

---

<a id="add-command"></a>
### Add a CLI command

1. Write a `cmd_<name>()` in `bin/atlas` — parse flags with a `while/case`, use
   the `_*` helpers (`_banner`/`_ok`/`_say`/`_die`), never `echo` raw errors.
2. Add a `case` arm in `main()`.
3. Document it in the header comment block (lines ~4–24) so `atlas help` shows it.
4. Add an assertion to `tests/bootstrap.test.sh` if it has logic worth pinning.
5. `shellcheck bin/atlas` must stay clean — mind SCARS §SET-E-AND-AND.

---

<a id="add-adapter"></a>
### Add a runtime adapter

1. `adapters/<runtime>/install.sh` — one idempotent script (re-running duplicates
   nothing; use a marker block like the existing adapters).
2. Add it to the README support table + the `atlas export` arm if the runtime has
   a context file.
3. Add an idempotency test to `tests/bootstrap.test.sh` (see the cursor/gemini ones).

---

<a id="add-channel"></a>
### Add a package channel

1. `packaging/<channel>/` with the manifest + any build script.
2. `.github/workflows/release-<channel>.yml`, triggered on `push: tags: ['v*']`
   (SCARS §TAG-TRIGGER-NOT-RELEASE — not `release: published`).
3. Add a row to `ATLAS.md` §6 + document setup in `docs/RELEASING.md`.

---

<a id="cut-release"></a>
### Cut a release

1. Move `CHANGELOG.md` `[Unreleased]` → `[X.Y.Z]`; bump `package.json`.
2. Commit, tag `vX.Y.Z`, `git push origin main --tags`.
3. The tag push fans out to every channel (npm/.deb/brew/AUR/PPA). Watch
   `gh run list`. Secrets + one-time setup: `docs/RELEASING.md`.
