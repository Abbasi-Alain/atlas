# atlas-demo.tape — vhs script for the README hero GIF.
#
# Generate from the repo root:  vhs assets/atlas-demo.tape
#
# Deliberately SLOW (130ms typing + 4–6s pauses) so a human can read every
# result. On-screen narration uses `echo` (not `#`) so it works in any shell.
# These `#` lines are vhs tape comments — they are NOT typed into the shell.

Output assets/atlas-demo.gif

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 760
Set Padding 26
Set TypingSpeed 130ms

# ─── setup (hidden): put atlas on PATH + make a tiny demo repo ───────
Hide
Type "export ATLAS_HOME=$PWD PATH=$PWD/bin:$PATH PS1='$ '"
Enter
Type "cd $(mktemp -d) && git init -q -b main"
Enter
Type "mkdir -p cmd internal"
Enter
Type "echo 'module shop' > go.mod; echo 'go 1.21' >> go.mod"
Enter
Type "touch cmd/main.go internal/cart.go internal/order.go README.md"
Enter
Type "clear"
Enter
Show

# ─── 1. the logo + tagline ──────────────────────────────────────────
Type "atlas version"
Sleep 1500ms
Enter
Sleep 4s

# ─── 2. scaffold the quartet + auto-draft the map from the repo ─────
Type "echo '— scaffold the 4-file quartet, and auto-draft the map —'"
Enter
Sleep 1500ms
Type "atlas init --analyze"
Sleep 1s
Enter
Sleep 6s

# ─── 3. validate ────────────────────────────────────────────────────
Type "atlas check"
Sleep 1s
Enter
Sleep 4s

# ─── 4. the value: orientation tokens saved ────────────────────────
Type "echo '— how many orientation tokens does it save? —'"
Enter
Sleep 1500ms
Type "atlas measure"
Sleep 1s
Enter
Sleep 6s

# ─── 5. fan out to every runtime from one source ───────────────────
Type "echo '— one source, every runtime —'"
Enter
Sleep 1500ms
Type "atlas export --to all"
Sleep 1s
Enter
Sleep 5s

# ─── 6. real A/B benchmark (dry-run, nothing burned) ───────────────
Type "echo '— real A/B benchmark (dry-run) —'"
Enter
Sleep 1500ms
Type "atlas bench --dry-run"
Sleep 1s
Enter
Sleep 6s

# hold the final frame
Sleep 3s
