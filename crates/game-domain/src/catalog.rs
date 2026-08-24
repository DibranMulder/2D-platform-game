//! The prototype's four maps, authored as fixed-point zone geometry. Values are
//! transcribed from `combat_arena.gd`/`.tscn` (client pixels, y-down) and
//! flipped to y-up world units via [`from_client_x`]/[`from_client_y`].

use crate::fixed::{from_client_x, from_client_y};
use crate::geometry::{
    Aabb, BUTTONCAP_HOLLOW, ClimbKind, ClimbVolume, EnemyKind, EnemySpawn, MOONLIT_MARKET,
    OneWayPlatform, PortalId, PortalVolume, SUNLIT_FOREST, SolidBox, SpawnId, SpawnPoint,
    THE_GAUNTLET, ZoneGeometry, ZoneId,
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
        Self {
            zones: vec![forest(), market(), hollow(), gauntlet()],
        }
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
        ],
        spawns: vec![
            spawn(spawn_ids::DEFAULT, 285, 549, 1),
            spawn(spawn_ids::FROM_MARKET, 1110, 549, -1),
            spawn(spawn_ids::FROM_HOLLOW, 175, 549, 1),
            spawn(spawn_ids::FROM_GAUNTLET, 640, 549, 1),
        ],
        enemy_spawns: vec![monster(760, 549)],
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
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_has_all_four_zones() {
        let catalog = ZoneCatalog::prototype();
        assert_eq!(catalog.all().len(), 4);
        for id in [SUNLIT_FOREST, MOONLIT_MARKET, BUTTONCAP_HOLLOW, THE_GAUNTLET] {
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
