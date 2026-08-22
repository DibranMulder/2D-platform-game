---
id: DESIGN-0010
title: World and Region Map hierarchy prototype
status: exploring
updated: 2026-08-22
---

# World and Region Map hierarchy prototype

## Question

Can one touch-friendly map hierarchy make eight Lineage Homelands, unclaimed
Frontier Territories, hundreds of playable Zones, Strongholds, Dungeon depths,
Hidden Zones, and physical Portal routes understandable without turning the map
into a fast-travel menu?

The current answer is explored through three switchable layouts inside the
combat prototype. **The Veiled Realms** is a working map title, and every
frontier name, border, route, and site location remains provisional.

## Geography model

A **Territory** is a map-scale geographic area containing one or more Zones.
The map currently distinguishes:

- Eight claimed Homeland Territories, one for every Lineage.
- Four Frontier Territories outside stable Lineage control.
- Four Dungeon Sites located inside Frontier Territories.
- Travel routes connecting Homeland and Frontier centers.

A Jungle is a Territory terrain; a Dungeon is a Site within a Territory. A
Dungeon therefore receives a marker rather than territorial borders or a
control state of its own.

## Navigation hierarchy

The UI uses familiar player-facing labels while the world model keeps each
scale distinct:

1. The **World Map** shows large clickable Territories, presented to players as
   Regions. It does not attempt to display every playable location.
2. Selecting a Region opens its **Region Map**.
3. A Region Map shows discovered **Zones**, presented to players as Maps, and
   the physical **Portals** connecting them.
4. Selecting a known Map shows its name, type, discovery state, neighboring
   Portals, services, Stronghold access, and Dungeon relationship. It does not
   teleport the Hero.
5. A Hero changes Maps only by walking through a Portal in the current Zone,
   unless a separately designed travel system is introduced later.

Every playable Zone must contain at least one traversable outbound Portal. A
leaf destination such as a ruler's chamber or final Dungeon Depth therefore
still has a return or exit Portal; content must never strand a Hero because its
node has no outgoing edge.

## Content scale target

The hierarchy must remain legible with hundreds of Zones. The first full-world
content budget should support roughly **320–500 Zones** without changing the UI:

| Territory kind | Count | Target Zones each | World contribution |
| --- | ---: | ---: | ---: |
| Lineage Homeland | 8 | 30–45 | 240–360 |
| Frontier Territory | 4 | 20–35 | 80–140 |

These are capacity and planning ranges, not a requirement to generate empty
filler. Stronghold and Dungeon Zones count toward their parent Territory total.
Additional Territories may be added without exposing their internal nodes on
the World Map.

## Region Map structure

A Region Map is a discoverable Portal graph laid over a hand-painted geographic
illustration. It should communicate adjacency and route structure more strongly
than literal distance.

- The current Zone receives the strongest marker and a subtle location pulse.
- Discovered Zones use illustrated landmarks instead of uniform circles.
- Portal connections read as roads, tunnels, currents, lifts, bridges, root
  paths, or other terrain-appropriate routes.
- A locked but known Portal may appear with its requirement. A Hidden Zone and
  its entering Portal remain absent until discovered; no empty node or obvious
  question mark reveals its guaranteed location.
- Region Maps may pan and zoom, but labels progressively reveal by zoom level so
  thirty to forty-five Zones do not appear simultaneously as a wall of text.
- Dungeon and Stronghold clusters may collapse to one landmark at low zoom and
  expand into their internal Zone graph when selected.

Discovery must be server-authored. If a Hidden Zone is intended to remain truly
secret, its definition and Portal condition cannot be recoverable from ordinary
client map data before discovery.

## Dungeon and Stronghold depth

Every Dungeon contains an entrance plus a path of at least **ten consecutive
Dungeon Depth Zones** before its deepest objective. Optional branches, loops,
shortcuts, Hidden Zones, rest rooms, minibosses, and return Portals may make the
graph richer, but they do not replace the ten-Zone minimum-depth path.

Every Lineage Stronghold contains **five to ten Zones**. A representative
Stronghold cluster may include an approach gate, courtyard, service district,
guard or training area, ceremonial hall, council or throne room, leader's
private chamber, treasury/archive, tower, sanctuary, or undercroft. The exact
institutions must fit the Lineage: “King's Room” is appropriate only where the
culture actually has a King, while another Stronghold may culminate in a
Council Grove, Tide Chamber, Forge Seat, or communal Hearth Hall.

Outer Villages remain separate from the restricted Stronghold count and connect
to the Stronghold approach through a physical Portal boundary where access can
be enforced.

## First visual-design pass

Before generating individual World, Region, or Zone art, compare three
structurally different map treatments using the selected cinematic
storybook-anime reference:

| Variant | World Map treatment | Region Map treatment |
| --- | --- | --- |
| A — Living Illustrated Atlas | Full-screen painted world with Territories defined by natural borders and landmark emblems | Geographic painting with landmark nodes and terrain-shaped Portal routes |
| B — Enchanted Chronicle | Open illuminated-book spread with Regions as painted chapters | Turned page reveals a Region diagram, discovery ink, and expandable Stronghold/Dungeon insets |
| C — Wayfinder Table | Magical cartographer's table with sculpted Region tokens and luminous boundaries | Layered relief map with glowing Portal threads and discovery fog |

All three use the same information and selected art direction; they differ in
layout, navigation metaphor, and information hierarchy rather than palette
alone. No individual Zone backgrounds should be mass-generated until one map
treatment is selected.

## Homeland Territories

| Territory | Lineage | Allegiance | Terrain | Stronghold approach |
| --- | --- | --- | --- | --- |
| Tidekin Sea | Tidekin | Light | Reefs, tidal terraces, mangroves, flooded halls | Amphibious docks leading to tidal gates |
| Open Lands | Humans | Light | Meadows, rivers, old roads, hill keeps | Crossroads village beneath a central keep |
| Elder Forests | Grove Centaurs | Light | Ancient canopy, root roads, luminous clearings | Broad living paths into the protected grove |
| Sky Reaches | Aeralith | Light | Floating mesas, wind bridges, cloud forests | Lower sky docks and controlled lifts |
| Broken Mountains | Crag Trolls | Dark | Storm peaks, quarries, sheer passes | Cliff village below monumental gates |
| Underdeep | Deep Goblins | Dark | Fungal caverns, rails, crystal seams | Trade tunnels and guarded surface elevators |
| Ember Desert | Sunscour | Dark | Dunes, basalt canyons, salt flats, cistern roads | Caravan village before a shaded bastion |
| Ice Lands | Rimeborn | Dark | Glaciers, black ridges, aurora fields | Thermal village outside insulated halls |

Every Homeland shows a triangular Stronghold marker and a square Outer Village
marker. Under the current rule, a Hero may enter allied Strongholds; an
Opposing-Allegiance Hero may enter the Outer Village but not the Stronghold.

## Frontier Territories and Dungeons

| Frontier Territory | Terrain promise | Known Dungeon Site | Initial danger label |
| --- | --- | --- | --- |
| Gloamfen Frontier | Mist swamp, drowned roads, luminous reeds | Mireglass Catacombs | Veteran |
| Ashen Scar | Volcanic badlands, glass fields, fumaroles | Cinder Vault | Elite |
| Shattered March | Ancient ruins, fractured roads, open scrub | Fallen Observatory | Group |
| Verdant Maw | Dense jungle, sinkholes, giant flora, lost temples | Coilroot Depths | Group |

Frontiers are open to both Allegiances and begin with no stable Lineage claim.
“Unclaimed” does not mean safe, empty, ownerless forever, or exempt from Open
Conflict rules. Claiming, settlement construction, resource control, and
territory warfare are future decisions rather than implied mechanics.

## Interactive layouts

The prototype deliberately offers three structurally different variants:

| Variant | Primary question | Structure |
| --- | --- | --- |
| A — Illustrated Atlas | Can players learn terrain and world identity at a glance? | Large colored territorial atlas with a detailed selected-region sidebar |
| B — Expedition Network | Can players plan exploration around routes and Dungeon Sites? | Wide route chart, marker filters, named Dungeons, and a compact expedition summary |
| C — Allegiance Control | Can players understand access before traveling? | Access-status roster beside a Light/Dark/Unclaimed control map |

The variant switcher is prototype-only. Once one direction is selected, the
winning hierarchy should be rewritten as the real map and the losing variants
removed from the main branch.

## Interaction model

- Press `M` or tap **M · MAP** to open or close the World Map.
- Click or tap a Territory to select it and update terrain, access, Stronghold,
  settlement, and Dungeon information; the accepted design will make a second
  click or explicit **Open Region** action enter the Region Map.
- Drag with mouse or one finger to pan.
- Use the mouse wheel, `+`/`−`, or visible zoom buttons to zoom.
- Use **Reset View** to return to the fitted full-world view.
- Use the bottom arrows or keyboard Left/Right to change prototype layout.
- Variant B filters map markers between All, Strongholds, and Dungeons.
- `Escape` closes the Hero overview and returns to the live combat prototype.

The maps are read-only. Clicking a Territory or Zone does not teleport the Hero,
queue travel, claim land, reveal hidden information, or change server state.

## Prototype implementation boundary

Map geography is temporary client data and is not authoritative. A production
World Map should render server-provided discovery, access, route, conflict, and
service information through stable Territory and Site identifiers. Hidden Sites
must not be discoverable by inspecting shipped client data if secrecy matters.

The prototype uses procedural polygons and markers so interaction and
information hierarchy can be tested before final map illustration exists. Its
borders are not navigation meshes, Zone boundaries, spawn rules, or legal
claims.

## Evaluation prompts

- Which variant best balances world fantasy, route planning, and political
  access—and which pieces should be combined?
- Should undiscovered Territories appear as silhouettes, fog, rumor text, or
  remain absent?
- Does the Underdeep need a separate underground map layer?
- Do the Sky Reaches need an altitude layer rather than sharing surface space?
- Should the Tidekin Sea include underwater depth layers and water-breathing
  requirements?
- Are Frontier Territories permanently unclaimed, claimable by clans, or only
  temporarily controlled through world events?
- Are Dungeon markers public, discovered per Hero, shared by parties, or sold as
  cartographic information?
- Does route danger show a level recommendation, environmental requirements,
  current PvP activity, or all three?
- Should Stronghold denial appear on the map before a Hero attempts travel?
- Which services exist in cross-Allegiance Outer Villages?
- Should the World Map transition into a Region Map by a second click, a large
  **Open Region** action, or a zoom-through animation?
- When a Dungeon cluster expands, should its ten-plus Depth Zones replace the
  Region Map, appear as an inset, or open a dedicated Dungeon Map?
- Which discoveries are per Hero, shared across an Account, or shared by party,
  clan, Allegiance, or the entire world?

## Validation log

| Check | Result | Date |
| --- | --- | --- |
| Twelve Territory polygon set | All polygons triangulate and render without errors | 2026-08-22 |
| Three layout variants | Atlas, Expedition, and Control variants rendered through Metal at 1280×720 | 2026-08-22 |
| Responsive map fitting | Complete world visible at default zoom in all three canvas proportions | 2026-08-22 |
| Territory hit-testing | Clicking the Verdant Maw selects the jungle Frontier | 2026-08-22 |
| Stronghold access | Light Hero allowed into Sky Reaches and denied Broken Mountains interior | 2026-08-22 |
| Dungeon lookup | Coilroot Depths correctly associated with the Verdant Maw | 2026-08-22 |
| Variant and zoom state | Layout switching and retained zoom passed interaction harness | 2026-08-22 |
| Physical phone/tablet gesture feel | Not yet tested on device | — |

## Change log

- 2026-08-22: Added the World Map → Region Map → Zone → Portal hierarchy,
  320–500-Zone capacity target, Hidden Zone discovery rule, ten-Depth Dungeon
  minimum, five-to-ten-Zone Strongholds, and three visual map treatments.
- 2026-08-22: Initial twelve-Territory map, four Frontier Dungeons, travel
  routes, Stronghold access display, touch/mouse controls, and three UI variants
  completed.
