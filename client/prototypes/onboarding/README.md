# Account and Hero Onboarding — Local Prototype

Run from the repository root:

```sh
godot --path client
```

The prototype exercises account creation, login, hero naming, the eight working
Lineages, hero selection, and entry into the combat arena. Everything is held in
memory and disappears when the game closes.

The launcher follows the Enchanted Chronicle UI direction under
`art-source/ui-concepts/enchanted-chronicle-v1/`: parchment reading surfaces,
night-glass live UI, antique-brass structure, crystal-cyan focus, quest-gold
primary actions, and the Alegreya SC/Alegreya Sans type system.

For the alternate login path, use the seeded local-only account:

```text
Email: demo@realm.test
Password: 123
```

To open the launcher directly on the denser Hero creation screen for visual
review:

```sh
godot --path client -- --preview-create-hero
```

This is deliberately not a real authentication implementation. Its question is
whether the vocabulary and onboarding flow are understandable before secure
backend identity work begins.
