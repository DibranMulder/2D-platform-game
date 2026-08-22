---
id: DESIGN-0012
title: Combat Classes and 1–120 equipment tiers
status: exploring
updated: 2026-08-22
---

# Combat Classes and 1–120 equipment tiers

## Curation boundary

This pass defines class identity, equipment silhouettes, armor-set families,
and weapon lines. It does **not** decide where an item is bought, crafted,
rewarded, found, or dropped. Those are separate acquisition records to design
after the item catalogue and creature roster are accepted.

The current `source` string on item definitions is therefore provisional. A
production model should not embed one source into an Item because one Item may
come from a shop, quest, recipe, event, chest, and several creature drop tables.
Later, an **Acquisition Entry** should link one Item to one acquisition method
with its own requirements, location, cost, probability, and availability.

## Proposed launch Combat Classes

Combat Class remains separate from Lineage. Every Lineage may choose every
Combat Class; Lineage determines the body rig and equipment-art variant, while
Combat Class determines combat actions and equipment permission.

| Combat Class | Combat promise | Primary weapons | Armor silhouette |
| --- | --- | --- | --- |
| Vanguard | Guard, counters, formation play, dependable melee | One-Handed Sword, One-Handed Axe, One-Handed Blunt, One-Handed Spear, Shield | Heavy plate, broad shoulders, closed or open helm |
| Ravager | Slow committed swings, stagger, armor breaking, risk and reward | Two-Handed Sword, Two-Handed Axe, Two-Handed Blunt, Polearm | Heavy or reinforced medium armor, open arms, weight-forward boots |
| Ranger | Ranged pressure, weak-point shots, traps, mobile fieldcraft | Bow, Crossbow, Spear | Medium leather and light mail, compact hood, bracers, practical boots |
| Duelist | Alternating paired-weapon attacks, evasion, bleeds, and precise counters | Two permitted One-Handed Weapons chosen from Dagger, Sword, and Axe | Light leather and cloth, asymmetric shoulder, fitted gloves, soft shoes |
| Arcanist | Elemental projectiles, zones, control, and fragile burst | Wand, Staff | Layered elemental robes, large readable sleeves, circlet or soft hat |
| Warden | Radiance healing and protection, Gloam curses and life transfer, or a balance of both | Wand, Staff | Polarity robes with asymmetric light and dark materials, open face, paired luminous and umbral focus details |

This six-Class roster covers every approved Weapon Family. Shared weapons are
intentional: a Spear behaves differently in the hands of a Ranger and Vanguard
because the Combat Class supplies the abilities. The Duelist alone receives
Dual Wield permission.

## Weapon permission matrix

| Weapon or Equipment Family | Vanguard | Ravager | Ranger | Duelist | Arcanist | Warden |
| --- | :---: | :---: | :---: | :---: | :---: | :---: |
| One-Handed Sword | Yes | — | — | Yes | — | — |
| Two-Handed Sword | — | Yes | — | — | — | — |
| One-Handed Axe | Yes | — | — | Yes | — | — |
| Two-Handed Axe | — | Yes | — | — | — | — |
| Spear | Yes | — | Yes | — | — | — |
| Polearm | — | Yes | — | — | — | — |
| Crossbow | — | — | Yes | — | — | — |
| Bow | — | — | Yes | — | — | — |
| Wand | — | — | — | — | Yes | Yes |
| Staff | — | — | — | — | Yes | Yes |
| Dagger | — | — | — | Yes | — | — |
| One-Handed Blunt | Yes | — | — | — | — | — |
| Two-Handed Blunt | — | Yes | — | — | — | — |
| Shield | Yes | — | — | — | — | — |
| Second One-Handed Weapon | — | — | — | Yes | — | — |

Grip remains authoritative. A Vanguard may place a Shield beside a permitted
One-Handed Weapon. A Duelist instead places a second permitted One-Handed
Weapon in Off Hand; the two weapons may use different permitted families. A
Two-Handed Weapon always reserves both hands.

## Equipment cadence from 1–120

Use twelve main visual tiers, each lasting ten Adventure Levels. Every tier has
a Base form for the first five levels and a Refined form for the second five.
The Refined form reuses the silhouette and animation overlay but adds trim,
material polish, particles, or a small attachment. This produces an upgrade
every five levels without demanding twenty-four unrelated armor concepts per
Class.

| Tier | Base requirement | Refined requirement | Intended power band |
| ---: | ---: | ---: | --- |
| 1 | 1 | 6 | 1–10 |
| 2 | 11 | 16 | 11–20 |
| 3 | 21 | 26 | 21–30 |
| 4 | 31 | 36 | 31–40 |
| 5 | 41 | 46 | 41–50 |
| 6 | 51 | 56 | 51–60 |
| 7 | 61 | 66 | 61–70 |
| 8 | 71 | 76 | 71–80 |
| 9 | 81 | 86 | 81–90 |
| 10 | 91 | 96 | 91–100 |
| 11 | 101 | 106 | 101–110 |
| 12 | 111 | 116 | 111–120 |

Quality is separate from Tier. A Rare level-26 Riversteel item is still Tier 3;
rarity may add stats or a special effect but does not invent a new progression
band.

## Standard armor-set contents

Every class set contains six visible pieces:

1. Head
2. Shoulders
3. Chest
4. Hands
5. Legs
6. Feet

Capes are generic equipment and never mandatory parts of a Class armor set.
Neck, Ring, Relic, and Cape are shared accessory lines. Main Hand and Off Hand
are also separate weapon records.

Piece wording follows the Class silhouette:

| Combat Class | Head | Shoulders | Chest | Hands | Legs | Feet |
| --- | --- | --- | --- | --- | --- | --- |
| Vanguard | Helm | Pauldrons | Cuirass | Gauntlets | Greaves | Sabatons |
| Ravager | Warhelm | Spaulders | Harness | Grips | Chausses | Warboots |
| Ranger | Hood | Shoulderguard | Jerkin | Bracers | Trousers | Trailboots |
| Duelist | Mask | Shoulder Sash | Doublet | Gloves | Breeches | Softboots |
| Arcanist | Circlet | Epaulets | Robe | Gloves | Legwraps | Slippers |
| Warden | Diadem | Polarity Mantle | Vestment | Handwraps | Legwraps | Boots |

Example expansion: the Tier 1 Vanguard family creates `Roadwarden Helm`,
`Roadwarden Pauldrons`, `Roadwarden Cuirass`, `Roadwarden Gauntlets`,
`Roadwarden Greaves` and `Roadwarden Sabatons`, plus Refined versions at level
6. A separately acquired generic Cape may be worn with the set.

## Armor family matrix

| Tier | Levels | Vanguard | Ravager | Ranger | Duelist | Arcanist | Warden |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1–10 | Roadwarden | Hearthsplitter | Greenpath | Quickstep | Candlewick | Candleveil |
| 2 | 11–20 | Copperleaf Guard | Boarhide | Brambletrail | Foxglove | Moonglass | Moonhalo |
| 3 | 21–30 | Riversteel | Stonehowl | Rainfeather | Silversash | Starling | Dawngloam |
| 4 | 31–40 | Stormward | Thunderhide | Cloudpiercer | Windlace | Skyglass | Tempest Veil |
| 5 | 41–50 | Mireguard | Bogbreaker | Miststrider | Gloamfox | Fenlight | Fen Eclipse |
| 6 | 51–60 | Cinderplate | Ashmaul | Glasshawk | Emberstep | Flamequartz | Ashen Halo |
| 7 | 61–70 | Crownroad | Ironmane | Farwatch | Roseblade | Dawnscript | Sunshadow |
| 8 | 71–80 | Runebastion | Runefang | Moontracker | Nightpetal | Astral Ink | Equinox |
| 9 | 81–90 | Deepward | Obsidian Roar | Holloweye | Shadeglass | Crystal Veil | Deep Eclipse |
| 10 | 91–100 | Starforged | Worldbreaker | Cometseeker | Eclipse | Constellation | Celestial Balance |
| 11 | 101–110 | Veilguard | Riftreaver | Horizon Hunter | Veilstep | Veilweaver | Threshold Veil |
| 12 | 111–120 | Everdawn | Last Thunder | Farstar | Dawnswift | High Chronicle | Eternal Twilight |

The names describe visual identity only. `Mireguard` does not mean the set must
drop in Gloamfen, and `Deepward` does not guarantee Underdeep acquisition.

## Weapon line matrix

Each cell is one named weapon record. Base and Refined forms use the Tier's two
requirements. Exact acquisition remains unassigned.

### Blades, axes, and reach weapons

| Tier | 1H Sword | 2H Sword | 1H Axe | 2H Axe | Spear | Polearm |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Roadworn Blade | Old Iron Greatblade | Woodcutter Hatchet | Split-Oak Greataxe | Ashwood Spear | Field Glaive |
| 2 | Copperleaf Sword | Briar Greatsword | Bramble Hatchet | Thornroot Greataxe | Thornpoint Spear | Leafhook Glaive |
| 3 | Riversteel Saber | Fallsong Greatblade | Ferry Axe | Fallsplitter Greataxe | Reedpoint Spear | Current Glaive |
| 4 | Stormward Sword | Thunder Greatsword | Gale Axe | Thunderhead Greataxe | Lightning Spear | Skyhook Halberd |
| 5 | Mireglass Blade | Bogiron Greatblade | Reedcleaver | Miremaw Greataxe | Boglance | Fenhook Glaive |
| 6 | Cindersteel Sword | Ember Greatsword | Ash Axe | Furnace Greataxe | Glasspoint Spear | Cinder Glaive |
| 7 | Crownroad Longsword | Ironmane Greatblade | Gilded Axe | Lionroar Greataxe | Banner Spear | Herald Halberd |
| 8 | Runeblade | Runecleaver Greatsword | Rune Hatchet | Runefang Greataxe | Moonscript Spear | Elder Glyph Glaive |
| 9 | Deepiron Blade | Obsidian Greatblade | Rail Axe | Crystal Cleaver | Crystalpoint Spear | Tunnel Halberd |
| 10 | Starforged Sword | Comet Greatsword | Star Axe | Worldbreaker Greataxe | Constellation Spear | Orbit Glaive |
| 11 | Veilguard Blade | Rift Greatblade | Rift Axe | Riftreaver Greataxe | Horizon Spear | Veil Halberd |
| 12 | Everdawn Sword | Last Thunder Greatsword | Everdawn Axe | Worldrend Greataxe | Firstlight Spear | Dawnspire Polearm |

### Ranged, arcane, defensive, and close weapons

| Tier | Crossbow | Bow | Wand | Staff | Shield | Dagger | 1H Blunt | 2H Blunt |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Crankwood Crossbow | Moonwood Bow | Hazel Sparkwand | Lantern Staff | Driftwood Buckler | Wayfarer's Dirk | Oak Knob Mace | Quarry Maul |
| 2 | Bramblebolt Crossbow | Greenbough Bow | Dewdrop Wand | Budding Staff | Leafguard Shield | Foxglove Dagger | Bellflower Mace | Rootknocker Maul |
| 3 | Lockgate Crossbow | Rainstring Bow | Brookglass Wand | River Lantern Staff | Ferry Shield | Minnow Dagger | Stonebell Mace | Bridgebreaker Maul |
| 4 | Stormcrank Crossbow | Cloudpiercer Bow | Zephyr Wand | Tempest Staff | Stormwall Shield | Windneedle Dagger | Thunderbell Mace | Skyfall Maul |
| 5 | Siltbolt Crossbow | Miststring Bow | Fenfire Wand | Reedlight Staff | Mireguard Shield | Gloamfang Dagger | Belltoad Mace | Causeway Maul |
| 6 | Vaultbolt Crossbow | Ashwing Bow | Ember Wand | Flamequartz Staff | Cinderplate Shield | Obsidian Dagger | Cinderbell Mace | Furnace Maul |
| 7 | Keepwatch Crossbow | Farwatch Longbow | Dawn Wand | Herald Staff | Liongate Shield | Roseblade Dagger | Crown Mace | Gatebreaker Maul |
| 8 | Runelock Crossbow | Moontracker Bow | Astral Wand | Runesong Staff | Runebastion Shield | Nightpetal Dirk | Glyph Mace | Rune Maul |
| 9 | Gearlock Crossbow | Holloweye Bow | Lumen Wand | Crystal Veil Staff | Deepward Shield | Shadeglass Dagger | Gearmace | Railbreaker Maul |
| 10 | Astrolabe Crossbow | Cometseeker Bow | Constellation Wand | Star Chart Staff | Starforged Aegis | Eclipse Dagger | Planetbell Mace | Falling Star Maul |
| 11 | Horizon Crossbow | Veilstring Bow | Rift Wand | Veilweaver Staff | Veilguard Shield | Veilstep Dagger | Riftbell Mace | Threshold Maul |
| 12 | Farstar Crossbow | Farstar Bow | Chronicle Wand | High Chronicle Staff | Everdawn Shield | Dawnswift Dagger | First Bell Mace | Last Gate Maul |

## Catalogue scale

If every Base and Refined form becomes a separate Item record, this launch plan
produces:

| Group | Calculation | Item records |
| --- | ---: | ---: |
| Class armor | 12 tiers × 6 Classes × 6 pieces × 2 forms | 864 |
| Weapon and Shield lines | 12 tiers × 14 families × 2 forms | 336 |
| Generic Capes and accessories | Deferred | — |
| Total defined by this document |  | **1,200** |

That count is appropriate for a long-running MMO database but too much unique
art for the first playable slice. The art-efficient implementation is:

- 72 base armor-set concepts: twelve for each of six Classes.
- 168 base weapon/shield concepts: twelve for each of fourteen families.
- Refined records reuse the base silhouette with a material, trim, attachment,
  or particle overlay.
- Each base concept is adapted to the approved body families rather than being
  baked into one Lineage sprite.

## Accepted curation decisions

- Vanguard, Ravager, Ranger, Duelist, Arcanist, and Warden are the starting
  Combat Classes.
- Duelists use two permitted One-Handed Weapons and do not use Shields.
- Wardens are polarity mages using Radiance, Gloam, or an Eclipse balance;
  Arcanists remain elemental mages.
- Full armor concepts advance every ten levels with a Refined midpoint at five.
- Capes are generic items rather than Class-set pieces.

Bulk Item records and equipment artwork still wait for talent-tree and naming
curation. The first full Class trees are drafted in
[`0013-class-talent-trees.md`](0013-class-talent-trees.md).
