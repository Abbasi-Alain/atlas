# atlas-demo.tape — vhs script for the public README hero GIF.
#
# Generate with: vhs assets/atlas-demo.tape
# Re-run when CLI surface or logo changes.
#
# Designed to be readable by a HUMAN — slow typing, long pauses,
# basic commands + real value-prop usage. Targets ~75 seconds.
#
# Note: shell '#' comments are NOT used as Type'd input — zsh interactive
# mode doesn't enable interactive_comments by default and would error.

Output assets/atlas-demo.gif

Set FontSize 18
Set Width 1200
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 80ms
Set PlaybackSpeed 1.0
Set Padding 30
Set Shell zsh

# Land in a fresh tmpdir so each take is reproducible.
Hide
Type "cd $(mktemp -d) && git init -q -b main && clear" Enter
Sleep 800ms
Show

# ─── 1. Show the logo + tagline ─────────────────────────────────────
Type "atlas version"
Sleep 500ms
Enter
Sleep 4000ms

# ─── 2. Show the help banner so the surface is visible ────────────
Type "atlas help | head -20"
Sleep 500ms
Enter
Sleep 5000ms

# ─── 3. Bootstrap a real project ────────────────────────────────────
Type "atlas init --style karpathy"
Sleep 500ms
Enter
Sleep 4500ms

# ─── 4. Show what landed (the trio + EXAMPLES + AGENTS mirror) ──────
Type "ls -la"
Sleep 400ms
Enter
Sleep 4000ms

# ─── 5. Validate (anchors unique, structure correct) ───────────────
Type "atlas check"
Sleep 500ms
Enter
Sleep 4000ms

# ─── 6. Show the SKILL anchors ──────────────────────────────────────
Type "atlas anchors"
Sleep 500ms
Enter
Sleep 4000ms

# ─── 7. Wire ATLAS into Claude Code (real installation) ─────────────
Type "atlas install --runtime claude-code"
Sleep 500ms
Enter
Sleep 4500ms

# ─── 8. Set up the mirror (GitLab → GitHub guardrail) ──────────────
Type "atlas mirror init"
Sleep 500ms
Enter
Sleep 4500ms

# ─── 9. Confirm what would push (auth status check) ────────────────
Type "atlas mirror status"
Sleep 500ms
Enter
Sleep 4500ms

# Hold the final frame so the reader can absorb it.
Sleep 3000ms
