# atlas-map.tape — the visual repo map.
#
# Generate from the repo root:  vhs assets/atlas-map.tape
#
# Runs on THIS repo (atlas dogfoods itself) so the graph is rich and real.
# `atlas map` in a terminal draws a Unicode graph; piped to a file it's Mermaid
# that renders on GitHub. The `#` lines are vhs tape comments.

Output assets/atlas-map.gif

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 700
Set Padding 26
Set TypingSpeed 90ms

Hide
Type "export ATLAS_HOME=$PWD PATH=$PWD/bin:$PATH PS1='$ '"
Enter
Type "clear"
Enter
Show

# ─── the terminal graph ─────────────────────────────────────────────
Type "echo '— a picture of your repo, right in the terminal —'"
Enter
Sleep 1200ms
Type "atlas map"
Sleep 800ms
Enter
Sleep 6s

# ─── same command, piped → Mermaid for GitHub ───────────────────────
Type "echo '— pipe it to a .md and it renders as Mermaid on GitHub —'"
Enter
Sleep 1200ms
Type "atlas map --mermaid | head -7"
Sleep 800ms
Enter
Sleep 5s

Sleep 2s
