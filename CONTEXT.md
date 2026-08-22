# Platform MMORPG

The shared language for a persistent, side-scrolling online world whose rules
are enforced by servers and presented by cross-platform clients.

## Identity and world

**Account**:
A player's authenticated identity, entitlements, and security history. An Account may own multiple Heroes.
_Avoid_: User, login

**Character**:
Any person-like figure represented in the world, whether player-controlled or not.
_Avoid_: Entity, player

**Hero**:
A persistent player-created Character owned by one Account, including a unique name, Lineage, progression, equipment, and social identity.
_Avoid_: Avatar, toon, player

**Session**:
A time-bounded, authenticated connection that permits one Account to control one Hero in a World Instance.
_Avoid_: Login, connection

**Lineage**:
A Hero's playable people, determining bodily form, inherited traits, and cultural origin but not combat profession.
_Avoid_: Race, class, species

**Combat Class**:
A Hero's learned combat profession or role, chosen separately from Lineage.
_Avoid_: Lineage, Discipline

**Allegiance**:
One of the world's two provisional cosmic-political groupings, Light or Dark, to which each Lineage currently belongs.
_Avoid_: White class, good race, faction

**Homeland**:
The terrain realm from which a Lineage originates and whose play space expresses that Lineage's culture.
_Avoid_: Terrain class, biome

**World Instance**:
An authoritative running partition of the world that simulates Characters and other Entities within one Zone.
_Avoid_: Server, shard, map

**Zone**:
A persistent place definition containing traversal, encounters, portals, and social rules. Multiple World Instances may run the same Zone.
_Avoid_: Level, map

**Entity**:
Anything with an authoritative identity and state inside a World Instance, including Heroes, creatures, projectiles, and loot.
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

**Discipline**:
A trainable field shared by every Hero, such as Attack, Strength, or Crafting, with its own XP and level from 1 to 99.
_Avoid_: Progression Skill, Stat, Talent, skill-tree node

**Total Level**:
The sum of all a Hero's Discipline levels, expressing breadth and accumulated progression without weighting one Discipline over another.
_Avoid_: Overall Level, combat level

**Overall Level**:
A Hero's general level derived from the combined levels of every Discipline and used to award Talent Points and gate Talent tiers.
_Avoid_: Total Level, Account level

**Talent**:
A Hero-specific passive or active capability unlocked with Talent Points in a Talent Tree.
_Avoid_: Discipline, level, Combat Skill

**Talent Tree**:
A prerequisite graph of Talents through which one Hero specializes independently of other Heroes on the same Account.
_Avoid_: Discipline list, ability bar

**Talent Point**:
A Hero-owned allocation resource earned through Overall Levels and spent to unlock Talents.
_Avoid_: Discipline XP, currency

**Item Pouch**:
A Hero's limited carried-item inventory, excluding items currently worn in Equipment Slots.
_Avoid_: Bank, equipment, backpack item

**Equipment Slot**:
A named location on a Hero's equipment overview that can hold one compatible item.
_Avoid_: Item Pouch slot, inventory category

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
