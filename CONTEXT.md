# Platform MMORPG

The shared language for a persistent, side-scrolling online world whose rules
are enforced by servers and presented by cross-platform clients.

## Identity and world

**Account**:
A player's authenticated identity, entitlements, and security history. An Account may own multiple Characters.
_Avoid_: User, login

**Character**:
A persistent in-world persona owned by one Account, including progression, equipment, and social identity.
_Avoid_: Avatar, player

**Session**:
A time-bounded, authenticated connection that permits one Account to control one Character in a World Instance.
_Avoid_: Login, connection

**World Instance**:
An authoritative running partition of the world that simulates Characters and other Entities within one Zone.
_Avoid_: Server, shard, map

**Zone**:
A persistent place definition containing traversal, encounters, portals, and social rules. Multiple World Instances may run the same Zone.
_Avoid_: Level, map

**Entity**:
Anything with an authoritative identity and state inside a World Instance, including Characters, creatures, projectiles, and loot.
_Avoid_: Object, actor

## Play

**Intent**:
A player's requested action, such as moving or jumping, that the authoritative simulation may accept or reject.
_Avoid_: Command, input event

**World Snapshot**:
A server-authored observation of visible Entity state at a particular Simulation Tick.
_Avoid_: Game state, frame

**Simulation Tick**:
One fixed-duration advancement of authoritative world rules.
_Avoid_: Frame, update

**Progression Skill**:
A trainable discipline that gains experience through relevant play and has its own level, independent of a Character's overall combat standing.
_Avoid_: Stat, ability

**Open Conflict**:
Rule-governed conflict between Characters in eligible locations, including reputation, clan, siege, and consequence rules.
_Avoid_: PvP mode, duel

**Basic Move**:
A universally available combat or traversal action with no long cooldown, such as Jump, Sword Attack, or Guard.
_Avoid_: Skill, spell

**Combat Skill**:
A hotbar action with a distinct tactical effect and cooldown or resource constraint.
_Avoid_: Basic Move, button

**Guard**:
A held defensive Basic Move that reduces incoming frontal damage while consuming stamina.
_Avoid_: Block skill, shield stance
