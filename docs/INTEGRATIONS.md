# Integrations — wiring ATLAS into agent runtimes

This guide covers the supported runtimes. Each integration aims to give your agents three things:

1. **Auto-orientation** at session start (read ATLAS.md and SKILL.md ToC without being asked).
2. **A CLI** they can call (`atlas init`, `atlas check`, `atlas anchors`, `atlas anchor add`).
3. **A documented anchor convention** they cite in commits and PRs.

---

## Claude Code

```bash
atlas install --runtime claude-code
```

What this does:
- Copies `hooks/atlas-skill-loader.sh` to `~/.claude/hooks/`.
- Registers it in `~/.claude/settings.json` as a `SessionStart` hook (idempotent — uses `jq` if available, else prints the snippet to paste).
- Installs `/init-atlas` slash command at `~/.claude/commands/init-atlas.md`.

Verify: open a new Claude Code session in any project with an ATLAS.md — you should see the orientation panel printed at startup.

### Per-project sub-agents

You can also add named sub-agents in `.claude/agents/<agent>.md` that *require* ATLAS+SKILL reading before any work. Example template at [`adapters/claude-code/sub-agent.template.md`](../adapters/claude-code/sub-agent.template.md).

---

## Codex CLI (OpenAI)

```bash
atlas install --runtime codex
```

What this does:
- Appends an `<!-- atlas-bootstrap:start -->`-delimited block to `~/.codex/AGENTS.md`.
- The block instructs Codex to read `./ATLAS.md` and `./.agents/skill/<project>/SKILL.md` at the start of every task.
- The marker delimiters make subsequent re-installs idempotent (they replace, not duplicate).

Codex inherits these instructions on every project, no matter where you run `codex` from.

---

## OpenCode (sst/opencode)

```bash
atlas install --runtime opencode
```

Same mechanism as Codex — appends a bootstrap block to `~/.config/opencode/AGENTS.md`. OpenCode reads this file as global context for every session.

---

## Hermes

```bash
atlas install --runtime hermes
```

Hermes (NousResearch/Hermes-Function-Calling and downstream forks) doesn't have a fixed config path — agents are launched programmatically. The adapter installs a portable system-prompt fragment at `~/.hermes/atlas-bootstrap.txt`. Your Hermes runner should prepend it to its system prompt:

```python
with open(os.path.expanduser("~/.hermes/atlas-bootstrap.txt")) as f:
    system_prompt = f.read() + "\n\n" + system_prompt
```

---

## Generic (any other runtime)

```bash
atlas install --runtime generic
```

Prints integration instructions. Two paths:

1. **Hook-driven** — run `~/.atlas/hooks/atlas-skill-loader.sh` on every session start and feed its stdout into your agent's initial context.
2. **Prompt-driven** — prepend a five-line instruction (printed by the installer) to your agent's system prompt.

If you build a first-class adapter for a popular runtime, please PR it to `adapters/<runtime>/`. The contract: a single executable `install.sh` that wires the bootstrap into the runtime's config and prints what it did.

---

## CI integration

To verify ATLAS.md and SKILL.md stay in sync, add `atlas check` to your CI:

```yaml
# .github/workflows/atlas.yml
name: atlas check
on: [pull_request]
jobs:
  atlas:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          curl -fsSL https://raw.githubusercontent.com/Abbasi-Alain/atlas/main/install.sh | bash
          ~/.local/bin/atlas check
```

Optionally fail the build if a structural diff isn't matched by an ATLAS update:

```bash
git diff --name-only origin/main | grep -E '^src/' \
  && ! git diff --name-only origin/main | grep -q '^ATLAS\.md$' \
  && { echo "structural change without ATLAS update — see SKILL §ATLAS-IS-INDEX"; exit 1; }
```
