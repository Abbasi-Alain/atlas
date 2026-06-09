# atlas-orient.tape — task-aware orientation (the agent's first move).
#
# Generate from the repo root:  vhs assets/atlas-orient.tape
#
# Runs on THIS repo so the map + SCARS are real. `atlas orient "<task>"` returns
# ONLY the relevant slice of the map, the playbook anchors, and the SCARS that
# bite that task — not the whole file. The `#` lines are vhs tape comments.

Output assets/atlas-orient.gif

Set Shell "bash"
Set FontSize 19
Set Width 1200
Set Height 760
Set Padding 26
Set TypingSpeed 80ms

Hide
Type "export ATLAS_HOME=$PWD PATH=$PWD/bin:$PATH PS1='$ '"
Enter
Type "clear"
Enter
Show

# ─── orient for a specific task ─────────────────────────────────────
Type "echo '— the agent’s first move: orient for THIS task, instead of grepping —'"
Enter
Sleep 1200ms
Type "atlas orient 'fix the release tag workflow'"
Sleep 800ms
Enter
Sleep 7s

Sleep 2s
