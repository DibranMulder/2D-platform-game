# Combat Arena Prototype — Throwaway

Run from the repository root:

```sh
godot --path client
```

Question: does an arrow-driven desktop layout and a touch drag-knob layout make
the same move/jump/attack/guard/four-skill combat loop understandable and fun?

Character-state panels are available from keyboard or the touch buttons above
the action bar:

- `B`: Item Pouch
- `C`: Equipment overview
- `L`: generic Discipline levels and simulated XP
- `K`: Hero-specific Talent Tree and point allocation
- `I`: battle controls and encounter hints

Battle guidance is collected in the Hints section instead of occupying the
arena HUD or appearing as instructional combat-log messages.

Use `Tab` or the weapon buttons below the action bar to switch between the five
combat loadouts. Slots `1`, `3`, `4`, `5`, and `6` change with the selected
weapon; hold `2` or `Shift` for its stance:

- **Sword:** quick melee, Parry, Power Strike, Whirlwind, and Lunge.
- **Axe + Shield:** slower heavy damage, strong frontal Guard, Shield Bash, and Charge.
- **Bow:** ranged arrows; hold Aim to empower the next Quick Shot.
- **Staff:** Arcane Bolt, Fireball, Frost Nova, Blink, Mend, and an Arcane Ward.
- **Wand:** rapid Magic Missiles, Twin Sparks, Hex Bolt, Phase Step, Mend, and an Arcane Ward.

Bow techniques consume Stamina. Staff and Wand spells consume Mana. All five
loadouts are immediately available in this throwaway arena for comparison.

Walk into the glowing portal at the edge of the Sunlit Forest to travel to
Mira's Moonlit Market. Approach Mira and press `E`, or tap **Trade**, to open
the local-only shop. Purchases use prototype gold and remain in memory until
the game closes; weapons are unique while supplies may be bought repeatedly.

The **Log Out** button in the upper-right ends the local prototype Session,
clears transient Hero state, and returns to the login screen.

The selected Hero's Lineage now controls the procedural battle silhouette. The
eight-Lineage GPU visual regression test requires a real renderer rather than
headless mode:

```sh
godot --path client --script \
  res://prototypes/combat_arena/lineage_visual_smoke.gd
```

This scene is intentionally offline, in-memory, and disposable. Relevant state
is always visible in the HUD: health, stamina, current action, cooldowns,
monster intent, and a short combat log. Record the verdict in
`docs/design/0005-combat-mechanics-prototype.md` before replacing this code.
