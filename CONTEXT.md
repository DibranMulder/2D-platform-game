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

**Lineage Variant**:
An allowed gender and bodily presentation within one Lineage; availability is Lineage-specific rather than universally male and female.
_Avoid_: Skin, Combat Class, mandatory gender pair

**Combat Class**:
A Hero's learned combat profession or role, chosen separately from Lineage.
_Avoid_: Lineage, Discipline

**Vanguard**:
A defensive martial Combat Class built around a One-Handed Weapon, Shield, Guard, counters, and formation protection.
_Avoid_: Tank, Warden

**Ravager**:
A heavy martial Combat Class using Two-Handed Weapons, committed attacks, stagger, and armor breaking.
_Avoid_: Berserker, Vanguard

**Ranger**:
A mobile martial Combat Class using Bows, Crossbows, fieldcraft, traps, and an optional creature bond.
_Avoid_: Hunter, Duelist

**Duelist**:
A mobile martial Combat Class that fights with a permitted One-Handed Weapon in each hand, combining alternating attacks, evasion, and feints.
_Avoid_: Rogue, universal dual wielding

**Arcanist**:
An elemental magical Combat Class using Wands or Staves to shape fire, frost, and storm magic.
_Avoid_: Warden, generic mage

**Warden**:
A polarity magical Combat Class using Wands or Staves to shape Radiance, Gloam, or a balance of both.
_Avoid_: Vanguard, nature warrior

**Radiance**:
The Warden spell school of light, revelation, healing, and protection; it is not the Light Allegiance and is not inherently morally good.
_Avoid_: Light Allegiance, holy faction

**Gloam**:
The Warden spell school of shadow, concealment, curses, and life transfer; it is not the Dark Allegiance and is not inherently morally evil.
_Avoid_: Dark Allegiance, evil magic

**Dual Wield**:
Equipping one permitted One-Handed Weapon in each hand; currently a defining Duelist permission rather than a universal One-Handed Weapon rule.
_Avoid_: Two-Handed Weapon, Weapon-and-Shield

**Allegiance**:
One of the world's two provisional cosmic-political groupings, Light or Dark, to which each Lineage currently belongs.
_Avoid_: White class, good race, faction

**Homeland**:
The terrain realm from which a Lineage originates and whose play space expresses that Lineage's culture.
_Avoid_: Terrain class, biome

**Stronghold**:
The fortified cultural heart of one Lineage's Homeland, with entry restricted by Allegiance.
_Avoid_: Capital, castle, dungeon

**Outer Village**:
A settlement surrounding or approaching a Stronghold that may be entered by Heroes of either Allegiance.
_Avoid_: Stronghold, neutral city

**Stronghold Guardian**:
A powerful server-controlled Character or creature that visibly protects a Stronghold and enforces its boundary.
_Avoid_: Monster, gate boss, bouncer

**Opposing Allegiance**:
Light from the perspective of Dark, or Dark from the perspective of Light.
_Avoid_: Wrong side, enemy race

**World Instance**:
An authoritative running partition of the world that simulates Characters and other Entities within one Zone.
_Avoid_: Server, shard, map

**Zone**:
A persistent place definition containing traversal, encounters, portals, and social rules. Multiple World Instances may run the same Zone.
_Avoid_: Level, map

**Territory**:
A map-scale geographic area containing one or more Zones, with a terrain identity and control state.
_Avoid_: Zone, level, map screen

**Frontier Territory**:
A Territory outside every Lineage's stable control, open to exploration, conflict, and future claims.
_Avoid_: Unclaimed biome, neutral Homeland, wilderness map

**Dungeon**:
A bounded adventure Site within a Territory, containing linked encounters and rewards but no territorial control by itself.
_Avoid_: Territory, level, cave

**World Map**:
The player-facing atlas of Territories, travel routes, Strongholds, Outer Villages, and known Sites.
_Avoid_: Zone, minimap, fast-travel menu

**Region Map**:
The player-facing view of one Territory's discovered Zones and the Portal routes between them.
_Avoid_: World Map, Territory, fast-travel menu

**Portal**:
A traversable connection from one Zone to another, represented physically inside the world rather than as automatic fast travel.
_Avoid_: World Map route, teleport menu, Region

**Hidden Zone**:
A Zone whose existence and entering Portal remain absent from the Region Map until the Hero satisfies its discovery condition.
_Avoid_: Secret Territory, instanced event, visible locked map

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

**Combat Equipment**:
A player-equippable Weapon or Shield carried visibly by a Hero and used by combat actions.
_Avoid_: Prop, tool, costume accessory

**Weapon Family**:
The shared handling and progression category of a Weapon: Sword, Axe, Spear, Polearm, Crossbow, Bow, Wand, Staff, Dagger, or Blunt.
_Avoid_: Combat Class, individual item, weapon skin

**Grip**:
The number of hands a Weapon requires: One-Handed or Two-Handed. A One-Handed Weapon leaves the other hand available for a Shield; a Two-Handed Weapon does not.
_Avoid_: Weapon Family, Equipment Slot

**Shield**:
Off-hand Combat Equipment that may be paired with any One-Handed Weapon but not with a Two-Handed Weapon.
_Avoid_: Weapon Family, Guard

**Exchange**:
A centralized player market that matches Buy Orders and Sell Orders for eligible items.
_Avoid_: Grand Exchange, auction house, vendor

**Buy Order**:
A standing offer to acquire a quantity of one eligible item at a maximum unit price.
_Avoid_: Bid, purchase request

**Sell Order**:
A standing offer to sell a quantity of one eligible item at a minimum unit price.
_Avoid_: Auction, listing

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
