---
id: DESIGN-0006
title: Account and hero onboarding
status: exploring
updated: 2026-08-22
---

# Account and hero onboarding

## Scope

The current onboarding prototype explores this flow:

```text
Create Account or Log In → Hero Roster → Choose Allegiance → Choose Lineage
→ Pick Unique Hero Name → Create Hero → Enter World → Log Out → Log In
```

It is intentionally in-memory. Passwords, Accounts, name reservations, and
Heroes disappear when the client closes. This makes the UX testable without
mistaking prototype storage for secure authentication.

## Canonical model

The eight concepts supplied as “classes” are modeled as **Lineages** because
they describe peoples, bodies, cultures, and origins. **Combat Class** remains a
separate future decision. “White classes” is normalized to **Light Allegiance**;
“good race” and “bad race” are avoided because individual Heroes may eventually
have moral agency independent of their origin.

| Allegiance | Working Lineage | Homeland | Source concept |
| --- | --- | --- | --- |
| Light | Tidekin | Sea | Amphibious, frog/lizard-like sea people |
| Light | Humans | Open Lands | Land-dwelling human realms |
| Light | Grove Centaurs | Forests | Centaur forest people |
| Light | Aeralith | Sky Reaches | Sky and wind people |
| Dark | Crag Trolls | Mountains | Mountain troll clans |
| Dark | Deep Goblins | Underdeep | Underground goblin people |
| Dark | Sunscour Legion | Ember Desert | Original desert soldier culture |
| Dark | Rimeborn | Ice Lands | Original frost-adapted people |

All names except Humans are working names. `Sunscour Legion` deliberately avoids
using Tolkien's Haradrim identity, and `Rimeborn` avoids copying the Frostlings
identity from *Age of Wonders*. Inspiration should result in original cultures,
silhouettes, histories, symbols, and names.

## Prototype rules

- Account email matching is case-insensitive.
- Prototype passwords require at least 12 characters.
- An Account may own up to eight Heroes.
- Hero names are 3–16 Latin letters with optional single spaces, apostrophes,
  or hyphens; matching is case-insensitive.
- Hero names are unique across all in-memory Accounts.
- Allegiance and Homeland are derived from Lineage, not selected independently.
- Lineage is fixed after creation in this prototype.
- Successful account creation also starts a local Session.
- Logging out from the combat arena clears the selected Hero and transient
  Hero-profile state before returning to login.

These are evaluation rules, not launch commitments. Internationalized names,
renaming, deletion, reservation expiry, cross-region uniqueness, and limits all
need explicit decisions before backend implementation.

## Production security boundary

The prototype must never be exposed as real authentication. The backend slice
must add password hashing with a memory-hard algorithm, durable account storage,
verified email or platform identity, generic login failures, rate limiting,
short-lived revocable Session tokens, TLS, secret rotation, recovery, audit
events, and abuse monitoring. Hero name allocation must become one atomic,
server-owned operation.

## Questions to resolve

- Is Allegiance cosmic, political, moral, or chosen independently by a Hero?
- Can an Account own Heroes from both Allegiances?
- Can a party, clan, or account mix Allegiances?
- Are Tidekin reptiles, amphibians, or a deliberate fantasy combination?
- Is each Homeland one Zone, a family of Zones, or a starting region?
- Can Heroes change Lineage, Combat Class, name, or Allegiance later?
- What scripts and diacritics must Hero names support at launch?

## Validation log

| Check | Result | Date |
| --- | --- | --- |
| Account creation and case-insensitive login | Passed automated Godot smoke test | 2026-08-22 |
| Eight-Lineage catalog and Allegiance filtering | Four Light and four Dark Lineages verified | 2026-08-22 |
| Hero creation and roster | Passed automated Godot smoke test | 2026-08-22 |
| Case-insensitive duplicate Hero name | Correctly rejected | 2026-08-22 |
| Login and Hero creation layouts | Rendered and visually inspected through Metal | 2026-08-22 |
| Combat arena logout navigation | Scene loads with touch-capable logout control and valid return target | 2026-08-22 |
| Production authentication and persistence | Deliberately not implemented | — |

## Change log

- 2026-08-22: Initial flow, terminology, working Lineages, security boundary,
  local UI, and state smoke test completed.
- 2026-08-22: Added combat-arena logout and explicit clearing of transient
  Session metadata.
