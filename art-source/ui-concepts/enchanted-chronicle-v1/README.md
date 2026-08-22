# Enchanted Chronicle UI System — v1

Status: visual design direction  
Target canvas: 1280×720, responsive through Godot `canvas_items` stretch  
Reference authority: `allegiance-lineages-v5` and `variant-b-enchanted-chronicle.png`

## Direction

The game UI behaves like a living companion volume to the Enchanted Chronicle
world map. Deliberate, paused interactions use warm illustrated paper; persistent
gameplay information uses translucent midnight-blue panels. Antique brass gives
components structure, while allegiance and magic colors communicate state rather
than decorate every surface.

- `ui-system-board.png` is the component and token overview.
- `npc-interaction-mockup.png` shows the system applied to live gameplay.
- `gear-pouch-drag-drop.png` defines the combined Item Pouch and Gear workflow.
- `disciplines-talent-tree.png` defines levels, derived stats, and the connected
  Talent Tree.
- Production text, icons, borders, and portraits should be separate Godot assets.
  Generated lettering is reference-only and must not be baked into final panels.

## Character menu architecture

The character menu uses one persistent top-level navigation row:

1. **Hero** — identity, allegiance, current build summary, and appearance.
2. **Gear & Pouch** — inventory and Equipment Slots in one drag-and-drop surface.
3. **Disciplines & Levels** — all twelve Discipline levels and XP progress.
4. **Talent Tree** — Hero-specific Talent allocation and prerequisites.

Gear and Pouch remain in one view because moving an item is one direct spatial
operation. Disciplines and Talents may share a combined wide view on desktop, as
shown in the concept, but become separate tabs when the viewport cannot preserve
readable tree geometry.

## Item Pouch and Gear Overview

`gear-pouch-drag-drop.png` is the target desktop composition.

- The pouch is always represented as six columns by four rows: exactly 24 slots.
- Occupied slots show an illustrated icon, quality corner pip, stack count, and
  wearable-slot glyph where applicable. Empty slots remain quiet but visible.
- The Gear Overview places all twelve Equipment Slots around the Hero: Head,
  Shoulders, Chest, Hands, Main Hand, Off Hand, Legs, Feet, Neck, Ring, Cape,
  and Relic.
- Empty Equipment Slots are valid targets, not disabled buttons. Their silhouette
  icon and text label remain visible for learnability and accessibility.
- Equipped items leave the pouch. A replacement is an atomic swap: the previous
  equipped item returns to the source pouch slot after the server accepts the move.

### Drag-and-drop states

1. **Resting:** item is fully opaque; wearable destination glyph is visible.
2. **Picked up:** source cell becomes a dashed vacancy and the drag preview is
   80–90% size at roughly 78% opacity. Stack count remains attached to the preview.
3. **Valid target:** destination uses a 2 px crystal-cyan ring, cyan connector or
   trajectory, and the text `Drop to equip`.
4. **Incompatible target:** hovered destination uses an ember-red ring plus a
   short reason such as `Requires Off Hand` or `Two-Handed weapon equipped`.
5. **Pending server:** preview snaps to the target, both source and destination
   show a restrained spinner, and further movement of those two items is blocked.
6. **Accepted:** destination flashes forest teal for 160 ms and the comparison
   rail updates.
7. **Rejected:** item returns to its source over 120 ms and the reason remains
   visible until dismissed or another item is selected.

Click/tap remains a supported shortcut: selecting an item opens its detail card
and an explicit `Equip` action. Controller users pick up with the primary action,
move focus between compatible slots, and release with the same action. Touch uses
a short hold before dragging so scrolling does not accidentally move items.

### Comparison rail

The right rail compares `Current` and `After equip` without requiring the drop.
Only changed values receive colored deltas. Improvements use forest teal with an
up arrow; reductions use ember red with a down arrow. Neutral values remain ivory.
The comparison is a client preview only; final values render from the accepted
server-authored equipment state.

## Levels and Disciplines

The progression header keeps Overall Level, Total Level, next-Overall progress,
and unspent Talent Points together. The twelve Discipline rows are grouped by
Martial, Mystic, and World, but every row retains the same anatomy:

- discipline icon and name;
- large level number;
- current-to-next-level XP bar;
- details affordance for XP totals, unlocks, and derived effects.

Do not include prototype `Train` buttons in the production view. XP changes arrive
from gameplay and the screen explains progress rather than manufacturing it.

## Talent Tree geometry

`disciplines-talent-tree.png` is intentionally a tree rather than three card
columns. The production graph follows these invariants:

- One shared, non-purchasable **Sword Mastery** root anchors the graph.
- The trunk visibly splits into three labeled limbs: **Blade**, **Guardian**, and
  **Wayfarer**.
- Talent nodes sit on visible parent-child connectors. A node with a prerequisite
  is never positioned as an unrelated card.
- Connectors render behind node buttons and remain thick enough to trace at the
  base 1280×720 viewport.
- The graph can pan and zoom. `Reset Tree` returns to a fitted view containing the
  root, all currently available nodes, and the focused node.
- At narrow widths the Talent Tree becomes its own screen; it never collapses into
  three vertical lists merely to share space with Disciplines.

Node state is encoded redundantly:

| State | Surface | Connector | Additional cue |
| --- | --- | --- | --- |
| Unlocked | Forest teal | Teal glow | Check or filled center |
| Available | Quest gold | Gold glow from parent | Point cost visible |
| Focused | Existing state plus cyan ring | Unchanged | 2 px cyan outer ring |
| Locked | Muted stone | Dark brass | Lock glyph and requirement text |

Input focus is independent from progression state: cyan always means current
keyboard/controller focus, never rarity, ownership, or affordability.

## Derived stat icon vocabulary

Icons accelerate scanning but never replace their localized text labels.

| Stat | Icon metaphor | Display form |
| --- | --- | --- |
| Damage | Crossed sword | Integer plus comparison delta |
| Armor | Shield | Integer plus comparison delta |
| Movement Speed | Winged boot | Percentage of base speed |
| Attack Speed | Circular blade or weapon with motion ring | Attacks per second |
| Critical Chance | Starburst | Percentage |
| Health | Heart | Integer maximum |
| Stamina | Leaf | Integer maximum |
| Mana | Crystal | Integer maximum |

Each icon uses a stable silhouette. Color may reinforce resource identity, but
the shape, label, number, and tooltip carry the meaning for color-blind players.

## Typography

Use one friendly, readable family pair rather than ornamental fantasy lettering.

| Role | Typeface | Weight | 1280×720 size | Use |
| --- | --- | --- | ---: | --- |
| Display | Alegreya SC | Medium | 32–40 px | Screen and chapter titles |
| Heading | Alegreya SC | Medium | 20–24 px | Panel names and NPC names |
| Button | Alegreya Sans | Medium | 17–18 px | Actions and tabs |
| Body | Alegreya Sans | Regular | 17–18 px | Dialogue, descriptions, chat |
| Caption | Alegreya Sans | Medium | 14–15 px | Hints, timestamps, metadata |
| Numeric | Alegreya Sans | Medium, tabular figures | 15–17 px | Health, currency, cooldowns |

Preserve sentence case for dialogue and descriptions. Reserve small caps or
uppercase for short tabs and section labels. Body copy should not use the display
face. Minimum live-game text is 14 px at the base viewport; dialogue and chat
default to at least 17 px.

## Core tokens

| Token | Value | Purpose |
| --- | --- | --- |
| `ink_navy` | `#101B2C` | HUD and chat surface |
| `book_blue` | `#183454` | Tabs, ribbons, secondary controls |
| `parchment` | `#F3E5BE` | Primary reading surface |
| `aged_paper` | `#D6BD84` | Secondary paper and separators |
| `antique_brass` | `#C79B48` | Frames and neutral focus structure |
| `warm_ivory` | `#FFF5D6` | Text on navy |
| `forest_teal` | `#2D756E` | Friendly reputation and confirmation |
| `crystal_cyan` | `#72D6E5` | Keyboard/controller/touch focus |
| `quest_gold` | `#F2C45F` | Quest action and unread attention |
| `ember_red` | `#B85645` | Destructive or dangerous action |
| `muted_stone` | `#78808A` | Disabled content and secondary metadata |

Use navy text on parchment at 90% or greater opacity and warm ivory on navy.
Decorative brass does not replace the cyan focus ring or red danger meaning.

## Materials and panels

The system has two primary panel families:

1. **Chronicle page** — parchment center, aged-paper edge, fine ink detail, double
   brass outer rule. Use for NPC dialogue, quests, lore, inventory, and maps where
   the Hero has paused to read or decide.
2. **Night glass** — `ink_navy` at 88–94% opacity with a restrained paper grain,
   book-blue inner edge, and thin brass keyline. Use for HUD, chat, tooltips, quest
   tracking, and information that overlays live movement.

Build frames as nine-slice textures. Keep botanical, leaf, crystal, or lineage
motifs in corner overlays so panels can resize without stretching ornament.

Base layout uses an 8 px spacing grid. Recommended radii are 4 px for fields,
6 px for buttons, and 8 px for large panels. Borders are 1 px inner ink plus 2 px
brass at the base viewport. Large panels use 24 px internal padding; compact HUD
panels use 12–16 px.

## Buttons

All actions share a chamfered book-tab silhouette. Desktop minimum height is
44 px; universal mouse/touch controls use 48 px; primary mobile actions use
56 px. Minimum touch width is 48 px with at least 8 px between targets.

| Variant | Surface | Meaning |
| --- | --- | --- |
| Primary | quest-gold paper, navy label | Accept, continue, equip, confirm |
| Secondary | book blue, ivory label | Trade, inspect, open, navigate |
| Quiet | transparent navy with brass keyline | Back, close, less prominent actions |
| Danger | ember red, ivory label | Decline, abandon, destroy |
| Disabled | desaturated navy/stone at 55% | Visible but unavailable action |
| Icon | circular navy or lineage-color medallion | HUD and compact actions |

Interaction states:

- Hover: raise luminance about 8%, brighten brass, 100 ms ease-out.
- Pressed: darken about 10% and translate content down 1 px.
- Focus: 2 px crystal-cyan outer ring plus a subtle inner glow; never color alone.
- Selected: retain focus ring and add a left marker or check glyph.
- Disabled: no glow or hover motion; explain the requirement in a tooltip.
- Loading: keep label width stable and replace the leading icon with a spinner.

## Chat

The chat system has three densities but one message model.

### Expanded

- Approximate desktop size: 420×260 px; minimum mobile width: 328 px.
- Tabs: World, Party, Clan, Whisper. An unread badge stays on inactive tabs.
- Messages use a 14–15 px timestamp, 16–17 px sender name, and 17 px body.
- System messages use quest gold, party names crystal cyan, clan names forest
  teal, whispers pale violet, and errors ember red. Body copy remains ivory.
- The input field is 48 px high with explicit send and emoji buttons.

### Compact in-world

- Three to five recent messages on a night-glass panel at roughly 75% opacity.
- Fades to 35% after inactivity but returns on message, hover, focus, or chat key.
- Keeps channel, sender, and message visible; hides input until activated.

### Collapsed

- One 48 px channel tab with unread count and expand affordance.
- Never collapses while the entry field is focused or accessibility reading mode
  is enabled.

Chat remains available during NPC interaction but is visually de-emphasized and
does not steal focus from response choices.

## NPC interaction flow

1. In range, show a compact night-glass prompt above or beside the NPC:
   `E · Speak` or the active controller/touch glyph.
2. On activation, stop Hero locomotion, preserve ambient animation, and dim the
   world by 10–15%. Do not blur or fully hide the environment.
3. Anchor a chronicle dialogue panel to the safe-area bottom. Keep Hero and NPC
   visible above it. Desktop target height is 210–240 px.
4. Overlap a 120–136 px portrait medallion on the left. Show NPC name, faction or
   reputation badge, and readable dialogue in the central parchment field.
5. Present no more than four visible response buttons. Order them quest/action,
   inquiry, commerce/service, and leave. The first enabled narrative choice gets
   focus; destructive choices never receive automatic focus.
6. `Continue` advances only non-branching dialogue. When choices exist, the
   chosen response is explicit; pressing the general continue key must not accept
   a quest accidentally.
7. Escape/back returns one conversation level, then closes. Closing restores
   movement only after the panel-out animation completes.

Quest gold signals a new or completable quest. Crystal cyan signals current
input focus. Forest teal signals friendly standing. Reputation and allegiance
must include a label or icon, never rely on color alone.

Recommended motion: 160 ms panel rise and fade, 100 ms button state changes,
220 ms portrait/name reveal. Respect reduced-motion settings by using opacity
only and keeping timing under 100 ms.

## Responsive behavior

- Respect a 32 px desktop safe area and platform-provided mobile safe-area insets.
- At widths below 900 px, response buttons stack below the dialogue text and the
  portrait reduces to 96 px.
- At widths below 700 px, chat collapses by default during conversation and the
  dialogue panel may use up to 45% of screen height.
- Controller focus order is dialogue → responses → auxiliary icons → chat.
- Mouse, keyboard, controller, and touch glyphs are runtime substitutions, not
  baked labels.
- All final text must be localization-safe. Buttons allow 40% label expansion;
  dialogue areas reflow vertically rather than shrinking type.

## Generation record

Mode: Codex built-in image generation.

1. **UI system board prompt:** create a high-fidelity 16:9 production UI kit from
   the selected lineage and Enchanted Chronicle references, covering typography,
   material/color tokens, button variants and states, chat densities, NPC dialogue,
   reputation, trade, HUD, and 48 px touch-safe components.
2. **Applied NPC prompt:** apply the approved board to a moonlit side-scrolling
   market scene with a small adventurer and Elder Rowan; show the persistent HUD,
   quest tracker, minimap, de-emphasized chat, and a bottom-anchored branching
   conversation panel without obscuring the characters.
3. **Gear and Pouch prompt:** create one integrated 16:9 character screen with an
   exact 6×4 Item Pouch, twelve anatomical Equipment Slots around the Hero, a
   visible Bronze Helm drag preview targeting Head, and an icon-plus-label stat
   comparison rail.
4. **Disciplines and Talent Tree prompt:** show the twelve canonical Disciplines,
   Overall and Total Level, icon-based derived stats, and a genuine connected tree
   with one Sword Mastery root, three labeled limbs, four talents per limb, visible
   prerequisites, and distinct unlocked, available, focused, and locked states.

The generated character names, dialogue, quest text, icons, numbers, and map
details are illustrative rather than final game content.
