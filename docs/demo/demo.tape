# README demo: NEXUS → M-01 briefing → mission → a recorded macro → :NeuroVim check.
# Reproducible: make demo. Plays in a throw-away config, state and save (XDG_*_HOME) — never the
# player's own config, ShaDa or save.
# vhs 0.12 writes 25 fps whatever Set Framerate says (measured); make demo converts this raw
# recording to the 20 fps GIF and MP4 the README embeds (D13: 20–24 fps).
Output docs/demo/.build/demo.mp4

Set Width 800
Set Height 520
Set FontSize 15
Set TypingSpeed 70ms
Set Padding 12

Hide
Type "D=$(mktemp -d); XDG_CONFIG_HOME=$D XDG_STATE_HOME=$D XDG_DATA_HOME=$D nvim -u docs/demo/init.lua" Enter
Sleep 1.5s
Show

Type ":NeuroVim" Enter
Sleep 2.5s
Type "/M-01" Enter
Sleep 0.5s
Enter
Sleep 3s
Enter
Sleep 2s
Type `gg0qa/\C[XZ]` Enter
Type "xq29@a"
Sleep 1.5s
Type ":NeuroVim check" Enter
Sleep 4s
