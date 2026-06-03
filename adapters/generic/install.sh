#!/usr/bin/env bash
# adapters/generic/install.sh
#
# No-op installer for runtimes without a first-class adapter.
# Prints integration instructions and a copy-paste-able snippet.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"

cat <<EOF
atlas[generic]: no per-runtime hook will be installed. To wire ATLAS
into your runtime, either:

  (a) On every session start, run the loader hook and feed its
      stdout into your agent's system prompt or initial context:

          $ATLAS_HOME/hooks/atlas-skill-loader.sh

  (b) Or, prepend this minimal instruction to your agent's system
      prompt:

          At the start of every task, if ./ATLAS.md exists, read
          it (graph index of every module). If
          ./.agents/skill/<project>/SKILL.md exists, read its Table
          of Contents (stable anchors of the form §NAME). Cite
          anchors in commit messages. Update ATLAS.md in the same
          commit as any structural change.

          Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md

  (c) Use the 'atlas' CLI from inside your agent:

          atlas init      # bootstrap ATLAS.md + SKILL.md
          atlas check     # validate
          atlas anchors   # list every SKILL anchor

If you build a first-class adapter for your runtime, please PR it to
https://github.com/Abbasi-Alain/atlas under adapters/<runtime>/.
EOF
