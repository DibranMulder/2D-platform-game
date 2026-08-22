# Combat Arena Prototype — Throwaway

Run from the repository root:

```sh
godot --path client
```

Question: does an arrow-driven desktop layout and a touch drag-knob layout make
the same move/jump/attack/guard/four-skill combat loop understandable and fun?

This scene is intentionally offline, in-memory, and disposable. Relevant state
is always visible in the HUD: health, stamina, current action, cooldowns,
monster intent, and a short combat log. Record the verdict in
`docs/design/0005-combat-mechanics-prototype.md` before replacing this code.

