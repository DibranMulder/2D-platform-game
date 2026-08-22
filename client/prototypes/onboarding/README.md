# Account and Hero Onboarding — Local Prototype

Run from the repository root:

```sh
godot --path client
```

The prototype exercises account creation, login, hero naming, the eight working
Lineages, hero selection, and entry into the combat arena. Everything is held in
memory and disappears when the game closes.

For the alternate login path, use the seeded local-only account:

```text
Email: demo@realm.test
Password: prototype123
```

This is deliberately not a real authentication implementation. Its question is
whether the vocabulary and onboarding flow are understandable before secure
backend identity work begins.

