//! Static, per-zone collision geometry, all in y-up world units.
//!
//! Geometry is authored once in [`crate::catalog`] (transcribed from the client
//! prototype's map tables) and never mutates at runtime. The physics in
//! [`crate::zone`] reads it to resolve movement.

/// Identifies one map / World Instance.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct ZoneId(pub u16);

pub const SUNLIT_FOREST: ZoneId = ZoneId(1);
pub const MOONLIT_MARKET: ZoneId = ZoneId(2);
pub const BUTTONCAP_HOLLOW: ZoneId = ZoneId(3);
pub const THE_GAUNTLET: ZoneId = ZoneId(4);

/// Stable wire/slug name for a zone.
pub fn zone_slug(id: ZoneId) -> &'static str {
    match id {
        SUNLIT_FOREST => "sunlit_forest",
        MOONLIT_MARKET => "moonlit_market",
        BUTTONCAP_HOLLOW => "buttoncap_hollow",
        THE_GAUNTLET => "the_gauntlet",
        _ => "unknown",
    }
}

/// Resolve a slug back to a zone id.
pub fn zone_by_slug(slug: &str) -> Option<ZoneId> {
    match slug {
        "sunlit_forest" => Some(SUNLIT_FOREST),
        "moonlit_market" => Some(MOONLIT_MARKET),
        "buttoncap_hollow" => Some(BUTTONCAP_HOLLOW),
        "the_gauntlet" => Some(THE_GAUNTLET),
        _ => None,
    }
}

/// Identifies a spawn point within a zone (portal targets reference these).
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct SpawnId(pub u16);

/// Identifies a portal within a zone.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct PortalId(pub u16);

/// Axis-aligned box in world units (inclusive bounds).
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Aabb {
    pub min_x: i32,
    pub min_y: i32,
    pub max_x: i32,
    pub max_y: i32,
}

impl Aabb {
    pub const fn new(min_x: i32, min_y: i32, max_x: i32, max_y: i32) -> Self {
        Self {
            min_x,
            min_y,
            max_x,
            max_y,
        }
    }

    /// Does this box contain the point (feet position of an entity)?
    pub const fn contains(&self, x: i32, y: i32) -> bool {
        x >= self.min_x && x <= self.max_x && y >= self.min_y && y <= self.max_y
    }
}

/// A fully solid block (walls, floor blocks). Bodies cannot pass through it
/// from any direction.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SolidBox {
    pub bounds: Aabb,
}

/// A one-way platform: a body lands on `top_y` only while descending, and
/// passes freely when moving up or when it holds "drop".
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct OneWayPlatform {
    pub top_y: i32,
    pub min_x: i32,
    pub max_x: i32,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ClimbKind {
    Ladder,
    Rope,
}

/// A ladder or rope volume. A body within horizontal proximity of `center_x`
/// and pressing a climb axis grabs it; gravity is suspended while climbing.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ClimbVolume {
    pub center_x: i32,
    pub top_exit_y: i32,
    pub bottom_exit_y: i32,
    pub kind: ClimbKind,
}

/// Where a hero appears when entering a zone (fresh join or via a portal).
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SpawnPoint {
    pub id: SpawnId,
    pub x: i32,
    pub y: i32,
    pub facing: i8,
}

/// A trigger volume that moves a hero to another zone's spawn.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PortalVolume {
    pub id: PortalId,
    pub bounds: Aabb,
    pub target: ZoneId,
    pub target_spawn: SpawnId,
}

/// The kind of enemy a spawn produces.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum EnemyKind {
    Monster,
    ButtoncapBiter,
}

/// A persistent enemy placement; the zone instantiates one enemy per spawn and
/// resets it here on respawn.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct EnemySpawn {
    pub kind: EnemyKind,
    pub x: i32,
    pub y: i32,
    pub patrol_min_x: i32,
    pub patrol_max_x: i32,
    pub facing: i8,
}

/// All static collision + placement data for one zone.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ZoneGeometry {
    pub id: ZoneId,
    pub ground_top_y: i32,
    pub min_x: i32,
    pub max_x: i32,
    pub solids: Vec<SolidBox>,
    pub one_ways: Vec<OneWayPlatform>,
    pub climbs: Vec<ClimbVolume>,
    pub portals: Vec<PortalVolume>,
    pub spawns: Vec<SpawnPoint>,
    pub enemy_spawns: Vec<EnemySpawn>,
}

impl ZoneGeometry {
    /// Resolve a falling/rising body's vertical landing for this tick.
    ///
    /// Given the body's `pos_x`, its previous feet `prev_y`, the intended
    /// `new_y = prev_y + vel_y`, and whether it is dropping through one-ways,
    /// returns `(resolved_y, grounded)`. It lands on the highest valid surface
    /// (solid ground plane, or a one-way platform crossed while descending).
    /// The caller zeroes vertical velocity when `grounded` is true.
    pub fn resolve_landing(
        &self,
        pos_x: i32,
        prev_y: i32,
        new_y: i32,
        vel_y: i32,
        drop_through: bool,
    ) -> (i32, bool) {
        let mut landing: Option<i32> = None;
        if new_y <= self.ground_top_y {
            landing = Some(self.ground_top_y);
        }
        // `<= 0` (not `< 0`) so a body resting motionless on a platform keeps
        // its footing instead of flickering to airborne each tick.
        if vel_y <= 0 && !drop_through {
            for platform in &self.one_ways {
                if prev_y >= platform.top_y
                    && new_y <= platform.top_y
                    && pos_x >= platform.min_x
                    && pos_x <= platform.max_x
                {
                    landing = Some(landing.map_or(platform.top_y, |y| y.max(platform.top_y)));
                }
            }
        }
        match landing {
            Some(y) => (y, true),
            None => (new_y, false),
        }
    }

    /// The spawn with the given id, falling back to the first spawn.
    pub fn spawn(&self, id: SpawnId) -> SpawnPoint {
        self.spawns
            .iter()
            .copied()
            .find(|spawn| spawn.id == id)
            .or_else(|| self.spawns.first().copied())
            .unwrap_or(SpawnPoint {
                id: SpawnId(0),
                x: 0,
                y: self.ground_top_y,
                facing: 1,
            })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slugs_round_trip() {
        for id in [SUNLIT_FOREST, MOONLIT_MARKET, BUTTONCAP_HOLLOW, THE_GAUNTLET] {
            assert_eq!(zone_by_slug(zone_slug(id)), Some(id));
        }
        assert_eq!(zone_by_slug("nope"), None);
    }

    #[test]
    fn aabb_contains_is_inclusive() {
        let box2 = Aabb::new(0, 0, 100, 100);
        assert!(box2.contains(0, 0));
        assert!(box2.contains(100, 100));
        assert!(!box2.contains(101, 50));
    }
}
