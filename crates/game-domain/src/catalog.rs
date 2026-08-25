//! The prototype's four maps, authored as fixed-point zone geometry. Values are
//! transcribed from `combat_arena.gd`/`.tscn` (client pixels, y-down) and
//! flipped to y-up world units via [`from_client_x`]/[`from_client_y`].

use crate::fixed::{from_client_x, from_client_y};
use crate::geometry::{
    Aabb, Allegiance, BUTTONCAP_HOLLOW, ClimbKind, ClimbVolume, EnemyKind, EnemySpawn,
    KINGSKEEP_BARRACKS, KINGSKEEP_GATEHOUSE, KINGSKEEP_GREAT_HALL, KINGSKEEP_KINGS_ROOM,
    KINGSKEEP_SERVICE, KINGSKEEP_TREASURY, MOONLIT_MARKET, NpcSpawn, OneWayPlatform, PortalId,
    PortalVolume, SUNLIT_FOREST, SolidBox, SpawnId, SpawnPoint, THE_GAUNTLET, TOWER_BASE,
    TOWER_SOLAR, TOWER_STAIR, WENDMERE_APOTHECARY, WENDMERE_APPROACH, WENDMERE_INN,
    WENDMERE_MARKET, WENDMERE_SQUARE, WENDMERE_TRAINERS, ZoneGeometry, ZoneId,
};

/// Spawn ids used by portal targets. Id 0 is always "fresh arrival / new join".
mod spawn_ids {
    use crate::geometry::SpawnId;
    pub const DEFAULT: SpawnId = SpawnId(0);
    pub const FROM_MARKET: SpawnId = SpawnId(1);
    pub const FROM_HOLLOW: SpawnId = SpawnId(2);
    pub const FROM_GAUNTLET: SpawnId = SpawnId(3);
}

/// Registry of all zone geometry. Const tables today, JSON-loadable later.
pub struct ZoneCatalog {
    zones: Vec<ZoneGeometry>,
}

impl ZoneCatalog {
    pub fn prototype() -> Self {
        let mut zones = vec![forest(), market(), hollow(), gauntlet()];
        zones.extend(human_town());
        Self { zones }
    }

    pub fn geometry(&self, id: ZoneId) -> &ZoneGeometry {
        self.zones
            .iter()
            .find(|zone| zone.id == id)
            .expect("catalog is missing a requested zone")
    }

    pub fn all(&self) -> &[ZoneGeometry] {
        &self.zones
    }
}

// --- helpers (client px in, world units out) ---

fn one_way(cx: i32, cy: i32, w: i32) -> OneWayPlatform {
    OneWayPlatform {
        top_y: from_client_y(cy - 11),
        min_x: from_client_x(cx - w / 2),
        max_x: from_client_x(cx + w / 2),
    }
}

fn climb(cx: i32, top_client_y: i32, bottom_client_y: i32, kind: ClimbKind) -> ClimbVolume {
    ClimbVolume {
        center_x: from_client_x(cx),
        // Higher on screen (smaller client y) is a larger world y.
        top_exit_y: from_client_y(top_client_y),
        bottom_exit_y: from_client_y(bottom_client_y),
        kind,
    }
}

#[allow(clippy::too_many_arguments)]
fn portal(
    id: u16,
    x0: i32,
    x1: i32,
    y_top: i32,
    y_bottom: i32,
    target: ZoneId,
    target_spawn: SpawnId,
) -> PortalVolume {
    PortalVolume {
        id: PortalId(id),
        bounds: Aabb::new(
            from_client_x(x0),
            from_client_y(y_bottom),
            from_client_x(x1),
            from_client_y(y_top),
        ),
        target,
        target_spawn,
        required_allegiance: None,
        manual: false,
    }
}

fn spawn(id: SpawnId, x: i32, y: i32, facing: i8) -> SpawnPoint {
    SpawnPoint {
        id,
        x: from_client_x(x),
        y: from_client_y(y),
        facing,
    }
}

fn monster(x: i32, y: i32) -> EnemySpawn {
    EnemySpawn {
        kind: EnemyKind::Monster,
        x: from_client_x(x),
        y: from_client_y(y),
        patrol_min_x: from_client_x(44),
        patrol_max_x: from_client_x(1236),
        facing: -1,
    }
}

fn biter(x: i32, y: i32, patrol_min: i32, patrol_max: i32) -> EnemySpawn {
    EnemySpawn {
        kind: EnemyKind::ButtoncapBiter,
        x: from_client_x(x),
        y: from_client_y(y),
        patrol_min_x: from_client_x(patrol_min),
        patrol_max_x: from_client_x(patrol_max),
        facing: 1,
    }
}

fn forest() -> ZoneGeometry {
    ZoneGeometry {
        id: SUNLIT_FOREST,
        ground_top_y: from_client_y(550),
        min_x: from_client_x(44),
        max_x: from_client_x(1236),
        solids: Vec::new(),
        one_ways: vec![one_way(590, 450, 210)],
        climbs: vec![climb(590, 438, 549, ClimbKind::Ladder)],
        portals: vec![
            portal(1, 1170, 1240, 435, 565, MOONLIT_MARKET, spawn_ids::DEFAULT),
            portal(2, 40, 110, 435, 565, BUTTONCAP_HOLLOW, spawn_ids::DEFAULT),
            // World road into the Human home town (DESIGN-0014): a manual door so
            // it does not intercept Heroes walking to the Market portal.
            door(3, 350, WENDMERE_SQUARE),
        ],
        spawns: vec![
            spawn(spawn_ids::DEFAULT, 285, 549, 1),
            spawn(spawn_ids::FROM_MARKET, 1110, 549, -1),
            spawn(spawn_ids::FROM_HOLLOW, 175, 549, 1),
            spawn(spawn_ids::FROM_GAUNTLET, 640, 549, 1),
        ],
        enemy_spawns: vec![monster(760, 549)],
        npc_spawns: Vec::new(),
    }
}

fn market() -> ZoneGeometry {
    ZoneGeometry {
        id: MOONLIT_MARKET,
        ground_top_y: from_client_y(550),
        min_x: from_client_x(44),
        max_x: from_client_x(1236),
        solids: Vec::new(),
        one_ways: Vec::new(),
        climbs: Vec::new(),
        // Returns to the Forest's "from market" spawn.
        portals: vec![portal(1, 35, 110, 435, 565, SUNLIT_FOREST, spawn_ids::FROM_MARKET)],
        spawns: vec![spawn(spawn_ids::DEFAULT, 155, 549, 1)],
        enemy_spawns: Vec::new(),
        npc_spawns: Vec::new(),
    }
}

fn hollow() -> ZoneGeometry {
    ZoneGeometry {
        id: BUTTONCAP_HOLLOW,
        ground_top_y: from_client_y(550),
        min_x: from_client_x(44),
        max_x: from_client_x(1236),
        solids: Vec::new(),
        one_ways: vec![
            one_way(300, 470, 240),
            one_way(640, 388, 220),
            one_way(980, 300, 240),
            one_way(500, 240, 180),
        ],
        climbs: Vec::new(),
        portals: vec![
            portal(1, 40, 110, 435, 565, SUNLIT_FOREST, spawn_ids::FROM_HOLLOW),
            portal(2, 1170, 1240, 435, 565, THE_GAUNTLET, spawn_ids::DEFAULT),
        ],
        spawns: vec![spawn(spawn_ids::DEFAULT, 170, 549, 1)],
        enemy_spawns: vec![
            biter(760, 549, 560, 1180),
            biter(980, 288, 875, 1085),
            biter(600, 376, 545, 735),
        ],
        npc_spawns: Vec::new(),
    }
}

fn gauntlet() -> ZoneGeometry {
    // (center_x, center_y, width) one-way platforms, straight from PARKOUR_PLATFORMS.
    let platforms = [
        (360, 500, 170),
        (600, 440, 150),
        (900, 250, 180),
        (1120, 330, 150),
        (1300, 410, 150),
        (1440, 400, 90),
        (1540, 340, 90),
        (1640, 280, 90),
        (1740, 220, 90),
        (1900, 220, 180),
        (2160, 470, 150),
        (2360, 400, 150),
        (2640, 180, 180),
        (2860, 260, 150),
        (3060, 330, 120),
        (3180, 380, 100),
        (3300, 430, 100),
        (3440, 470, 220),
    ];
    ZoneGeometry {
        id: THE_GAUNTLET,
        ground_top_y: from_client_y(550),
        min_x: from_client_x(30),
        max_x: from_client_x(3570),
        solids: Vec::<SolidBox>::new(),
        one_ways: platforms
            .iter()
            .map(|&(cx, cy, w)| one_way(cx, cy, w))
            .collect(),
        climbs: vec![
            climb(760, 250, 430, ClimbKind::Rope),
            climb(2500, 180, 400, ClimbKind::Rope),
            climb(2000, 220, 560, ClimbKind::Ladder),
        ],
        // The finish banner returns to the Forest's "from gauntlet" spawn.
        portals: vec![portal(
            1, 3400, 3480, 420, 560, SUNLIT_FOREST, spawn_ids::FROM_GAUNTLET,
        )],
        spawns: vec![spawn(spawn_ids::DEFAULT, 140, 500, 1)],
        enemy_spawns: Vec::new(),
        npc_spawns: Vec::new(),
    }
}

// --- Human home town: Wendmere Crossroads, the King's Keep, the Princess's
// Tower (DESIGN-0014). All rooms are the standard 1280x720 side-scroll room with
// ground at y550; portals are ground-level doorways unless noted. ---

/// A ground-level doorway centered at client x `cx`, targeting the destination's
/// default spawn.
fn door(id: u16, cx: i32, target: ZoneId) -> PortalVolume {
    let mut portal = portal(id, cx - 40, cx + 40, 460, 565, target, spawn_ids::DEFAULT);
    portal.manual = true; // town doors are entered deliberately (press up)
    portal
}

/// A manual door raised off the ground (e.g. atop a climb), at client y span.
fn high_door(id: u16, cx: i32, y_top: i32, y_bottom: i32, target: ZoneId) -> PortalVolume {
    let mut portal = portal(id, cx - 50, cx + 50, y_top, y_bottom, target, spawn_ids::DEFAULT);
    portal.manual = true;
    portal
}

/// A doorway gated to one Allegiance (the Stronghold boundary).
fn gated_door(id: u16, cx: i32, target: ZoneId, allegiance: Allegiance) -> PortalVolume {
    let mut portal = door(id, cx, target);
    portal.required_allegiance = Some(allegiance);
    portal
}

fn tnpc(role: &'static str, name: &'static str, x: i32, facing: i8) -> NpcSpawn {
    NpcSpawn {
        role,
        name,
        x: from_client_x(x),
        y: from_client_y(549),
        facing,
    }
}

/// A standard town room: flat ground, given platforms/portals/NPCs, one default
/// spawn at client x `spawn_x`.
fn town_room(
    id: ZoneId,
    spawn_x: i32,
    one_ways: Vec<OneWayPlatform>,
    portals: Vec<PortalVolume>,
    npcs: Vec<NpcSpawn>,
) -> ZoneGeometry {
    ZoneGeometry {
        id,
        ground_top_y: from_client_y(550),
        min_x: from_client_x(44),
        max_x: from_client_x(1236),
        solids: Vec::new(),
        one_ways,
        climbs: Vec::new(),
        portals,
        spawns: vec![spawn(spawn_ids::DEFAULT, spawn_x, 549, 1)],
        enemy_spawns: Vec::new(),
        npc_spawns: npcs,
    }
}

// --- Wendmere Village Square: a 5120x2880 layered map authored in
// village-square-layout-v1.svg. Coordinates below are the SVG's (y-down, origin
// top-left); the sq* helpers flip to y-up world units with a 2880 baseline. ---
const SQ_HEIGHT: i32 = 2880;
const SQ_GROUND: i32 = 2400; // plaza floor top (SVG y)

fn sqx(px: i32) -> i32 {
    px * 100
}
fn sqy(px: i32) -> i32 {
    (SQ_HEIGHT - px) * 100
}
fn sq_platform(x0: i32, x1: i32, top: i32) -> OneWayPlatform {
    OneWayPlatform {
        top_y: sqy(top),
        min_x: sqx(x0),
        max_x: sqx(x1),
    }
}
fn sq_ladder(cx: i32, top: i32, bottom: i32) -> ClimbVolume {
    ClimbVolume {
        center_x: sqx(cx),
        top_exit_y: sqy(top),
        bottom_exit_y: sqy(bottom),
        kind: ClimbKind::Ladder,
    }
}
fn sq_portal(id: u16, x: i32, y: i32, w: i32, h: i32, target: ZoneId) -> PortalVolume {
    PortalVolume {
        id: PortalId(id),
        bounds: Aabb::new(sqx(x), sqy(y + h), sqx(x + w), sqy(y)),
        target,
        target_spawn: spawn_ids::DEFAULT,
        required_allegiance: None,
        manual: true,
    }
}
fn sq_npc(role: &'static str, name: &'static str, x: i32, y: i32, facing: i8) -> NpcSpawn {
    NpcSpawn {
        role,
        name,
        x: sqx(x),
        y: sqy(y),
        facing,
    }
}

fn wendmere_square() -> ZoneGeometry {
    ZoneGeometry {
        id: WENDMERE_SQUARE,
        ground_top_y: sqy(SQ_GROUND),
        min_x: sqx(40),
        max_x: sqx(5080),
        solids: Vec::new(),
        one_ways: vec![
            // West climb: three wall ledges.
            sq_platform(540, 1370, 2020),
            sq_platform(980, 1900, 1630),
            sq_platform(1540, 2390, 1240),
            // East watch-tower: four floors plus the top walkway to the gate.
            sq_platform(3300, 4560, 2000),
            sq_platform(3440, 4420, 1580),
            sq_platform(3580, 4300, 1160),
            sq_platform(3700, 4480, 720),
            sq_platform(4300, 5060, 760),
        ],
        climbs: vec![
            // West ladders: ground -> ledge1 -> ledge2 -> ledge3.
            sq_ladder(620, 2020, SQ_GROUND),
            sq_ladder(1370, 1630, 2020),
            sq_ladder(1900, 1240, 1630),
            // East ladders: ground -> f1 -> f2 -> f3 -> f4.
            sq_ladder(3420, 2000, SQ_GROUND),
            sq_ladder(4300, 1580, 2000),
            sq_ladder(3580, 1160, 1580),
            sq_ladder(4240, 720, 1160),
        ],
        portals: vec![
            sq_portal(1, 30, 2140, 230, 290, SUNLIT_FOREST), // Open Lands road (ground, far-left)
            sq_portal(2, 2180, 1020, 250, 330, WENDMERE_TRAINERS), // west top ledge
            sq_portal(3, 4100, 2280, 250, 320, WENDMERE_APOTHECARY), // lower-right (raised to ground reach)
            sq_portal(4, 4860, 2130, 240, 310, WENDMERE_MARKET), // far-right ground arch
            sq_portal(5, 4740, 560, 300, 340, WENDMERE_APPROACH), // high east gate (via tower climb)
        ],
        spawns: vec![SpawnPoint {
            id: spawn_ids::DEFAULT,
            x: sqx(2480),
            y: sqy(SQ_GROUND),
            facing: 1,
        }],
        enemy_spawns: Vec::new(),
        npc_spawns: vec![
            sq_npc("sentry", "Gate Sentry", 520, SQ_GROUND, 1),
            sq_npc("lorekeeper", "Herald of Wendmere", 2080, SQ_GROUND, -1),
            sq_npc("exchange_broker", "Exchange Broker", 2900, SQ_GROUND, -1),
            sq_npc("wildlife", "Meadow Puffkin", 1590, SQ_GROUND, 1),
            sq_npc("sentry", "Watch Sentry", 4650, 760, -1),
        ],
    }
}

fn human_town() -> Vec<ZoneGeometry> {
    vec![
        // --- Ring 1: Wendmere Crossroads (Outer Village) ---
        wendmere_square(),
        town_room(
            WENDMERE_MARKET,
            300,
            Vec::new(),
            vec![door(1, 90, WENDMERE_SQUARE)],
            vec![
                tnpc("weaponsmith", "Weaponsmith", 500, 1),
                tnpc("armorer", "Armorer", 760, -1),
                tnpc("wandwright", "Wandwright", 980, -1),
            ],
        ),
        town_room(
            WENDMERE_APOTHECARY,
            300,
            Vec::new(),
            vec![door(1, 90, WENDMERE_SQUARE)],
            vec![
                tnpc("apothecary", "Apothecary", 520, 1),
                tnpc("provisioner", "Provisioner", 780, -1),
            ],
        ),
        town_room(
            WENDMERE_TRAINERS,
            220,
            Vec::new(),
            vec![door(1, 90, WENDMERE_SQUARE), door(2, 1150, WENDMERE_INN)],
            vec![
                tnpc("trainer_vanguard", "Vanguard Trainer", 320, 1),
                tnpc("trainer_ravager", "Ravager Trainer", 440, 1),
                tnpc("trainer_ranger", "Ranger Trainer", 560, 1),
                tnpc("trainer_duelist", "Duelist Trainer", 680, 1),
                tnpc("trainer_arcanist", "Arcanist Trainer", 800, 1),
                tnpc("trainer_warden", "Warden Trainer", 920, 1),
            ],
        ),
        town_room(
            WENDMERE_INN,
            640,
            Vec::new(),
            vec![door(1, 90, WENDMERE_TRAINERS)],
            vec![
                tnpc("innkeeper", "Innkeeper", 520, 1),
                tnpc("quartermaster", "Quartermaster", 760, -1),
            ],
        ),
        town_room(
            WENDMERE_APPROACH,
            250,
            Vec::new(),
            vec![
                door(1, 90, WENDMERE_SQUARE),
                gated_door(2, 1150, KINGSKEEP_GATEHOUSE, Allegiance::Light),
            ],
            vec![
                tnpc("sentry", "Approach Sentry", 700, 1),
                tnpc("guardian", "Stronghold Guardian", 1000, -1),
            ],
        ),
        // --- Ring 2: the King's Keep (Stronghold, Light-gated) ---
        town_room(
            KINGSKEEP_GATEHOUSE,
            300,
            Vec::new(),
            vec![
                door(1, 90, WENDMERE_APPROACH),
                door(2, 640, KINGSKEEP_SERVICE),
                door(3, 1150, KINGSKEEP_BARRACKS),
            ],
            vec![tnpc("sentry", "Keep Sentry", 450, 1)],
        ),
        town_room(
            KINGSKEEP_BARRACKS,
            300,
            Vec::new(),
            vec![
                door(1, 90, KINGSKEEP_GATEHOUSE),
                door(2, 1150, KINGSKEEP_GREAT_HALL),
            ],
            vec![tnpc("captain", "Warden Captain", 620, 1)],
        ),
        town_room(
            KINGSKEEP_SERVICE,
            300,
            vec![one_way(520, 470, 180), one_way(820, 400, 180)],
            vec![door(1, 90, KINGSKEEP_GATEHOUSE)],
            vec![tnpc("cook", "Keep Cook", 660, 1)],
        ),
        town_room(
            KINGSKEEP_GREAT_HALL,
            780,
            Vec::new(),
            vec![
                door(1, 90, KINGSKEEP_BARRACKS),
                door(2, 300, KINGSKEEP_TREASURY),
                door(3, 520, TOWER_BASE), // quest road to the Princess's Tower
                door(4, 1180, KINGSKEEP_KINGS_ROOM),
            ],
            vec![tnpc("lorekeeper", "Court Herald", 700, -1)],
        ),
        town_room(
            KINGSKEEP_KINGS_ROOM,
            640,
            Vec::new(),
            vec![door(1, 90, KINGSKEEP_GREAT_HALL)],
            vec![tnpc("king", "King (placeholder)", 700, -1)],
        ),
        town_room(
            KINGSKEEP_TREASURY,
            640,
            Vec::new(),
            vec![door(1, 90, KINGSKEEP_GREAT_HALL)],
            vec![tnpc("treasurer", "Treasurer", 700, -1)],
        ),
        // --- Ring 3: the Princess's Tower (Story Site, open) ---
        town_room(
            TOWER_BASE,
            300,
            Vec::new(),
            vec![
                door(1, 90, KINGSKEEP_GREAT_HALL),
                door(2, 1150, TOWER_STAIR),
            ],
            vec![tnpc("sentry", "Tower Watch", 640, 1)],
        ),
        // The Winding Stair: a climb of one-way ledges; the exit to the Solar sits
        // on the top ledge, so the Hero must ascend to leave.
        town_room(
            TOWER_STAIR,
            200,
            vec![
                one_way(320, 470, 170),
                one_way(560, 390, 170),
                one_way(800, 310, 170),
                one_way(980, 235, 170),
            ],
            vec![door(1, 90, TOWER_BASE), high_door(2, 980, 165, 285, TOWER_SOLAR)],
            Vec::new(),
        ),
        town_room(
            TOWER_SOLAR,
            640,
            Vec::new(),
            vec![door(1, 90, TOWER_STAIR)],
            vec![tnpc("princess", "Princess (placeholder)", 700, -1)],
        ),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_has_the_overworld_and_human_town() {
        let catalog = ZoneCatalog::prototype();
        // 4 overworld prototype maps + 15 Human home-town zones.
        assert_eq!(catalog.all().len(), 19);
        for id in [
            SUNLIT_FOREST,
            MOONLIT_MARKET,
            BUTTONCAP_HOLLOW,
            THE_GAUNTLET,
            WENDMERE_SQUARE,
            KINGSKEEP_KINGS_ROOM,
            TOWER_SOLAR,
        ] {
            assert_eq!(catalog.geometry(id).id, id);
        }
    }

    #[test]
    fn forest_ground_and_platform_are_yup() {
        let forest = forest();
        assert_eq!(forest.ground_top_y, 17_000);
        // The one-way ledge (client top y=439) sits above the ground.
        assert!(forest.one_ways[0].top_y > forest.ground_top_y);
        assert_eq!(forest.one_ways[0].top_y, 28_100);
    }

    #[test]
    fn every_portal_targets_a_real_spawn() {
        let catalog = ZoneCatalog::prototype();
        for zone in catalog.all() {
            for portal in &zone.portals {
                let target = catalog.geometry(portal.target);
                assert!(
                    target.spawns.iter().any(|s| s.id == portal.target_spawn),
                    "zone {:?} portal -> {:?} spawn {:?} missing",
                    zone.id,
                    portal.target,
                    portal.target_spawn
                );
            }
        }
    }
}
