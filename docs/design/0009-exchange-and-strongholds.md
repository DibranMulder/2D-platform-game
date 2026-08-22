---
id: DESIGN-0009
title: Exchange and Lineage Strongholds
status: proposed
updated: 2026-08-22
---

# Exchange and Lineage Strongholds

## Purpose

This record captures two future social-world features: a centralized player
market inspired by the convenience of RuneScape's Grand Exchange, and one
protected home Stronghold for every playable Lineage. It specifies original
game rules and terminology rather than copying another game's name, interface,
locations, item catalog, or presentation.

Nothing in this record is implemented in the current local prototypes.

## Confirmed feature requirements

- Players can trade eligible items through a centralized Exchange.
- Every Lineage has a home Stronghold inside its Homeland.
- A Hero from the Opposing Allegiance cannot enter a Stronghold.
- Powerful Stronghold Guardians protect each restricted boundary.
- Outer Villages around the Strongholds remain enterable by both Allegiances.

## Access interpretation

“Wrong side” means **Opposing Allegiance**, not a different Lineage. Under the
current working interpretation, a Human may enter a Tidekin Stronghold because
both are Light; a Deep Goblin may enter a Rimeborn Stronghold because both are
Dark. Whether a Stronghold contains an inner Lineage-only sanctuary remains an
open question.

| Visiting Hero | Outer Village | Stronghold interior |
| --- | --- | --- |
| Same Lineage | Allowed | Allowed |
| Allied Lineage, same Allegiance | Allowed | Allowed |
| Opposing Allegiance | Allowed | Denied |
| Mixed-Allegiance party | Allowed individually | Each Hero checked individually |

Village access means the Hero may physically enter. It does not yet decide
whether the village is a safe zone, permits Open Conflict, offers every service,
or changes guard reactions through reputation.

## Authoritative Stronghold boundary

The server must own the access decision. Stronghold Guardians communicate and
support the rule, but they are not its only enforcement: defeating, distracting,
or pathing around a Guardian must not let an Opposing-Allegiance Hero cross the
boundary. Portals, flight, death respawns, party summons, disconnect recovery,
and future fast travel must apply the same access policy.

A denied approach should have readable escalation:

1. Boundary markers, architecture, banners, and sentries communicate ownership.
2. A Guardian warns the approaching Hero before combat when practical.
3. Continuing forward causes the boundary to reject entry and Guardians to
   engage or repel the Hero.
4. Defeat returns the Hero to a legal nearby location rather than spawning them
   inside the restricted Stronghold.

Stronghold Guardians should be dangerous enough that the boundary feels
credible. They should not become profitable farming targets: rewards, respawn
behavior, pursuit distance, assistance calls, and exploit monitoring must be
designed around their security role. They may include sentient guards, bonded
guardian creatures, constructs, or environmental defenses appropriate to the
Lineage; “Monster” is not the canonical term for all of them.

## Stronghold and village themes

These are environment prompts, not final place names.

| Lineage | Stronghold direction | Open Outer Village direction |
| --- | --- | --- |
| Tidekin | A defensible coral-and-shell citadel reached through tidal gates | Amphibious docks, raised walkways, markets, and air-filled guest quarters |
| Humans | A road-linked hill keep with layered walls, banners, and a central hall | Farms, inns, workshops, caravan yards, and a multicultural roadside market |
| Grove Centaurs | A living grove enclosed by ancient roots and guarded forest paths | Broad woodland clearings and root-road settlements sized for varied bodies |
| Aeralith | A high sky-spire reached by controlled lifts, bridges, and wind passages | Lower sky docks, sheltered terraces, courier houses, and lift stations |
| Crag Trolls | A monumental mountain hold carved behind storm-battered gates | Quarry terraces, rope-hoist yards, forge markets, and cliffside lodgings |
| Deep Goblins | A fortified Underdeep nexus controlling tunnels, rails, and ventilation | Fungal farms, machine bazaars, trade tunnels, and guarded surface elevators |
| Sunscour | A shaded desert bastion built around protected water and route control | Caravan courts, cistern plazas, glassworks, and heat-sheltered trading streets |
| Rimeborn | An insulated ice hold around geothermal warmth and aurora-lit halls | Windbreak camps, thermal pools, supply depots, and enclosed guest houses |

Each approach should transition clearly from shared village space to controlled
Stronghold space. The boundary must remain legible in a 2D side-scrolling view
without relying solely on an invisible wall or a wall of UI text.

## Exchange proposal

The **Exchange** is a server-owned market for asynchronous player trading. It
uses orders rather than requiring two Heroes to meet, remain online, or agree
through a manual trade window.

### Initial player flow

1. Search or browse an eligible item.
2. Review current offers and server-produced price history.
3. Create a Buy Order with quantity and maximum unit price, or a Sell Order with
   quantity and minimum unit price.
4. Move offered currency or items into server-owned escrow.
5. Match compatible orders using price priority followed by creation time.
6. Support partial fills until the order fills, expires, or is canceled.
7. Deliver acquired items, proceeds, and unused escrow to a claimable balance.

Proposed order states are `Open`, `Partially Filled`, `Filled`, `Canceled`,
`Expired`, and `Claimed`. Naming, order limits, fees, taxes, expiry duration,
and claim locations require economy testing before acceptance.

### Initial item scope

The first version should trade standardized, stackable commodities and equipment
whose identity is completely described by an item definition and quantity.
Individually rolled equipment, bound items, quest objects, currencies, services,
and Account entitlements should remain ineligible until their pricing and fraud
risks are designed explicitly.

### World placement

A useful working proposal is to place Exchange Brokers in Outer Villages and
other shared settlements so both Allegiances can access trade without entering
an Opposing Stronghold. Whether every Broker accesses one world-wide order book,
separate regional markets, or Allegiance-specific books is unresolved. A shared
book offers better liquidity; separated books create transport and conflict
gameplay but are harder for new or low-population regions.

Direct Hero-to-Hero trading, gifting, mail attachments, clan storage, delivery
contracts, and transport loss are separate future features. They must not be
assumed merely because the Exchange exists.

## Economy security and anti-cheat

The client may display and request trades but never decides ownership, balance,
price matching, or fulfillment.

- Currency and items enter escrow atomically when an order is accepted.
- Each order and claim operation uses an idempotency key.
- Matching, partial fills, cancellation, fees, and delivery are one durable
  transactional workflow with conserved item and currency totals.
- The server validates ownership, quantity, tradability, order limits, and
  available capacity before accepting an order.
- Every state transition produces an auditable ledger entry.
- Rate limits and bot evidence apply to search, order creation, cancellation,
  and rapid repricing.
- Suspicious circular trades, wash trading, price manipulation, duplication,
  compromised Accounts, and real-money-trading patterns are recorded for
  investigation without treating a client binary as trusted evidence.
- Backup restoration and reconciliation must prove that no item or currency is
  silently created or destroyed.

The Exchange cannot launch against client-side inventory or in-memory Account
state. It depends on authenticated Accounts and durable server-owned inventory,
currency, and Hero persistence.

## Boundary scenarios

- A Light Human may trade in a Crag Troll Outer Village but is stopped at the
  Crag Troll Stronghold gate.
- A Dark Deep Goblin may enter the Rimeborn Stronghold under the current
  same-Allegiance rule.
- A mixed party can explore an Outer Village together; only individually legal
  members may continue into the Stronghold.
- Defeating every visible Guardian does not disable the authoritative boundary.
- An Exchange cancellation racing with a partial fill settles exactly once and
  returns only the remaining escrow.
- A disconnected buyer may later claim completed purchases without the seller
  being online.

## Open decisions

- Is same Allegiance always sufficient for Stronghold entry, or is an inner
  sanctuary restricted to the home Lineage?
- Can reputation, quests, diplomacy, disguise, or defection change access?
- Can siege or war temporarily override the boundary, and who owns the
  Stronghold afterward?
- Are Outer Villages safe zones, guarded peace zones, or Open Conflict areas?
- Do village services differ for the home, allied, and Opposing Allegiances?
- Is the Exchange world-wide, regional, or separated by Allegiance?
- Which items are eligible, and are prices fixed to one currency?
- What order limits, taxes, price history, and anti-manipulation controls create
  a healthy market without punishing ordinary players?

## Delivery dependencies

1. Durable Account, Hero, inventory, equipment, and currency persistence.
2. Authenticated Session and server-owned item definitions.
3. Atomic inventory and currency ledger with idempotent operations.
4. Zone access policy enforced by the authoritative World Instance.
5. Exchange order matching, escrow, claiming, and audit history.
6. Stronghold and Outer Village content, Guardians, services, and navigation.
7. Economy simulation, exploit testing, load testing, and live-operations tools.

## Change log

- 2026-08-22: Initial Exchange, Stronghold access, Guardian enforcement, Outer
  Village, economy security, and delivery dependencies recorded.
