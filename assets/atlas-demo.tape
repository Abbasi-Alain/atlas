# atlas-demo.tape — vhs script for the README hero GIF.
#
# Generate from the repo root:  vhs assets/atlas-demo.tape
#
# Shows the *newest* surface: one-command onboard (scaffold + auto-draft map +
# measure), the Mermaid map, the MCP snippet, the self-refreshing git hook, and
# check. Built on a small but REAL Go service (assets/demo-fixture.sh) so the
# numbers and the graph are believable, not a toy.
#
# Narration uses `echo` (not `#`) so it shows on screen in any shell. The `#`
# lines here are vhs tape comments — they are NOT typed into the shell.

Output assets/atlas-demo.gif

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 760
Set Padding 26
Set TypingSpeed 90ms

# ─── setup (hidden): atlas on PATH + a small, REAL demo service ──────
# Clean, short cwd (/tmp/shopd) so the on-screen paths read nicely.
Hide
Type "export ATLAS_HOME=$PWD PATH=$PWD/bin:$PATH PS1='$ '"
Enter
Type "rm -rf /tmp/shopd && mkdir -p /tmp/shopd && cd /tmp/shopd && git init -q -b main"
Enter
Type "bash $ATLAS_HOME/assets/demo-fixture.sh"
Enter
Type "clear"
Enter
Show

# ─── 1. identity ────────────────────────────────────────────────────
Type "atlas version"
Sleep 1200ms
Enter
Sleep 3s

# ─── 2. ONE command: scaffold + auto-draft the map + measure ────────
Type "echo '— one command: scaffold the quartet · auto-draft the map · measure —'"
Enter
Sleep 1200ms
Type "atlas onboard"
Sleep 800ms
Enter
Sleep 7s
Type "clear"
Enter

# ─── 3. a picture of the repo (Mermaid, pastes into any Markdown) ────
Type "echo '— a picture of your repo (paste into any Markdown) —'"
Enter
Sleep 1200ms
Type "atlas map"
Sleep 800ms
Enter
Sleep 5s
Type "clear"
Enter

# ─── 4. serve the map to every agent over one MCP snippet ───────────
Type "echo '— serve the map to ANY agent: one MCP snippet works everywhere —'"
Enter
Sleep 1200ms
Type "atlas mcp --config"
Sleep 800ms
Enter
Sleep 5s
Type "clear"
Enter

# ─── 5. a map that cannot rot ───────────────────────────────────────
Type "echo '— a git hook keeps the map fresh on every commit —'"
Enter
Sleep 1200ms
Type "atlas hooks install --auto"
Sleep 800ms
Enter
Sleep 4s
Type "clear"
Enter

# ─── 6. validate: map and playbook stay in sync ─────────────────────
Type "echo '— validate: map and playbook stay in sync —'"
Enter
Sleep 1200ms
Type "atlas check"
Sleep 800ms
Enter
Sleep 4s

# hold the final frame
Sleep 3s
