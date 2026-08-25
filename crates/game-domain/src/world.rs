//! The whole game world: every zone plus the routing table mapping each player
//! to the zone that currently owns their hero. One sim task advances all zones
//! in sequence each tick, so the single-writer rule (DESIGN-0002) holds
//! trivially; per-zone tasks can come later behind the same interface.

use std::collections::BTreeMap;

use crate::catalog::ZoneCatalog;
use crate::entity::ZoneSnapshot;
use crate::geometry::{SUNLIT_FOREST, ZoneId};
use crate::hero::{Hero, HeroDescriptor, WeaponId};
use crate::intent::{IntentError, JoinError, PlayerIntent};
use crate::zone::Zone;
use crate::PlayerId;

/// A hero moved between zones this tick (via a portal).
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ZoneTransfer {
    pub player_id: PlayerId,
    pub from: ZoneId,
    pub to: ZoneId,
    pub spawn_x: i32,
    pub spawn_y: i32,
    pub facing: i8,
}

/// Everything produced by one world tick.
pub struct TickOutcome {
    pub server_tick: u64,
    pub snapshots: Vec<ZoneSnapshot>,
    pub transfers: Vec<ZoneTransfer>,
}

/// The Zone a freshly created Hero of this Lineage spawns into (its home town's
/// Village Square). Only the Human town is built so far; others fall back.
fn home_zone_for(lineage: &str) -> ZoneId {
    match lineage {
        "human" => crate::geometry::WENDMERE_SQUARE,
        _ => SUNLIT_FOREST,
    }
}

pub struct World {
    catalog: ZoneCatalog,
    zones: BTreeMap<ZoneId, Zone>,
    player_zone: BTreeMap<PlayerId, ZoneId>,
    starting_zone: ZoneId,
    server_tick: u64,
}

impl Default for World {
    fn default() -> Self {
        Self::new(ZoneCatalog::prototype())
    }
}

impl World {
    pub fn new(catalog: ZoneCatalog) -> Self {
        let mut zones = BTreeMap::new();
        for geometry in catalog.all() {
            zones.insert(geometry.id, Zone::new(geometry.clone()));
        }
        Self {
            catalog,
            zones,
            player_zone: BTreeMap::new(),
            starting_zone: SUNLIT_FOREST,
            server_tick: 0,
        }
    }

    pub fn server_tick(&self) -> u64 {
        self.server_tick
    }

    /// Every zone id in the world (used to pre-create per-zone broadcast channels).
    pub fn zone_ids(&self) -> Vec<ZoneId> {
        self.zones.keys().copied().collect()
    }

    /// Place a new hero in the starting zone. Returns the zone it entered.
    pub fn join(&mut self, player_id: PlayerId, descriptor: HeroDescriptor) -> Result<ZoneId, JoinError> {
        if self.player_zone.contains_key(&player_id) {
            return Err(JoinError::AlreadyJoined);
        }
        // Route to the Hero's home town by Lineage, falling back to the shared
        // starting zone if that town's zones are not built yet.
        let mut zone_id = home_zone_for(&descriptor.lineage);
        if !self.zones.contains_key(&zone_id) {
            zone_id = self.starting_zone;
        }
        let spawn = self
            .catalog
            .geometry(zone_id)
            .spawn(crate::geometry::SpawnId(0));
        let hero = Hero::new(player_id, descriptor, spawn);
        self.zones
            .get_mut(&zone_id)
            .expect("starting zone exists")
            .insert_hero(hero);
        self.player_zone.insert(player_id, zone_id);
        Ok(zone_id)
    }

    pub fn leave(&mut self, player_id: PlayerId) -> bool {
        if let Some(zone_id) = self.player_zone.remove(&player_id) {
            if let Some(zone) = self.zones.get_mut(&zone_id) {
                zone.remove_hero(player_id);
            }
            true
        } else {
            false
        }
    }

    pub fn zone_of(&self, player_id: PlayerId) -> Option<ZoneId> {
        self.player_zone.get(&player_id).copied()
    }

    pub fn submit_intent(&mut self, player_id: PlayerId, intent: PlayerIntent) -> Result<(), IntentError> {
        let zone_id = *self.player_zone.get(&player_id).ok_or(IntentError::UnknownPlayer)?;
        self.zones
            .get_mut(&zone_id)
            .ok_or(IntentError::UnknownPlayer)?
            .submit_intent(player_id, intent)
    }

    pub fn set_weapon(&mut self, player_id: PlayerId, weapon: WeaponId) -> bool {
        let Some(&zone_id) = self.player_zone.get(&player_id) else {
            return false;
        };
        let Some(zone) = self.zones.get_mut(&zone_id) else {
            return false;
        };
        zone.set_hero_weapon(player_id, weapon)
    }

    pub fn advance_tick(&mut self) -> TickOutcome {
        self.server_tick = self.server_tick.saturating_add(1);

        let mut snapshots = Vec::with_capacity(self.zones.len());
        let mut crosses = Vec::new();
        for zone in self.zones.values_mut() {
            let (snapshot, zone_crosses) = zone.advance_tick(self.server_tick);
            snapshots.push(snapshot);
            crosses.extend(zone_crosses.into_iter().map(|cross| (zone.id(), cross)));
        }

        let mut transfers = Vec::new();
        for (from, cross) in crosses {
            // Remove the hero from its source zone and relocate to the target.
            let Some(mut hero) = self
                .zones
                .get_mut(&from)
                .and_then(|zone| zone.remove_hero(cross.player_id))
            else {
                continue;
            };
            let spawn = self.catalog.geometry(cross.target).spawn(cross.target_spawn);
            hero.relocate(spawn);
            self.zones
                .get_mut(&cross.target)
                .expect("portal target zone exists")
                .insert_hero(hero);
            self.player_zone.insert(cross.player_id, cross.target);
            transfers.push(ZoneTransfer {
                player_id: cross.player_id,
                from,
                to: cross.target,
                spawn_x: spawn.x,
                spawn_y: spawn.y,
                facing: spawn.facing,
            });
        }

        TickOutcome {
            server_tick: self.server_tick,
            snapshots,
            transfers,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::entity::EntitySnapshot;
    use crate::geometry::{MOONLIT_MARKET, SUNLIT_FOREST};

    fn descriptor(name: &str) -> HeroDescriptor {
        // Non-Human so these forest-based tests still spawn in the forest.
        HeroDescriptor {
            hero_name: name.to_owned(),
            lineage: "tidekin".to_owned(),
            weapon: WeaponId::Sword,
            allegiance: crate::geometry::Allegiance::Light,
        }
    }

    fn intent(sequence: u64, move_axis: i8, jump: bool) -> PlayerIntent {
        PlayerIntent {
            sequence,
            client_tick: sequence,
            move_axis,
            climb_axis: 0,
            jump,
            drop: false,
            guard: false,
            action_slot: 0,
        }
    }

    fn heroes_in_zone(outcome: &TickOutcome, zone: ZoneId) -> Vec<u64> {
        outcome
            .snapshots
            .iter()
            .find(|s| s.zone == zone)
            .map(|s| {
                s.entities
                    .iter()
                    .filter_map(|e| match e {
                        EntitySnapshot::Hero(h) => Some(h.player_id.get()),
                        _ => None,
                    })
                    .collect()
            })
            .unwrap_or_default()
    }

    fn hero_y(outcome: &TickOutcome, zone: ZoneId, player: u64) -> i32 {
        outcome
            .snapshots
            .iter()
            .find(|s| s.zone == zone)
            .unwrap()
            .entities
            .iter()
            .find_map(|e| match e {
                EntitySnapshot::Hero(h) if h.player_id.get() == player => Some(h.position_y),
                _ => None,
            })
            .unwrap()
    }

    #[test]
    fn join_places_a_hero_in_the_forest() {
        let mut world = World::default();
        let player = PlayerId::new(1);
        assert_eq!(world.join(player, descriptor("Aria")).unwrap(), SUNLIT_FOREST);
        assert_eq!(world.zone_of(player), Some(SUNLIT_FOREST));
        assert_eq!(
            world.join(player, descriptor("Aria")),
            Err(JoinError::AlreadyJoined)
        );
    }

    #[test]
    fn a_jump_rises_then_returns_to_the_ground() {
        let mut world = World::default();
        let player = PlayerId::new(1);
        world.join(player, descriptor("Aria")).unwrap();

        world.submit_intent(player, intent(1, 0, true)).unwrap();
        let first = world.advance_tick();
        let after_jump = hero_y(&first, SUNLIT_FOREST, 1);

        let mut peak = after_jump;
        let mut last = TickOutcome {
            server_tick: 0,
            snapshots: Vec::new(),
            transfers: Vec::new(),
        };
        for tick in 2..40 {
            world.submit_intent(player, intent(tick, 0, false)).unwrap();
            last = world.advance_tick();
            peak = peak.max(hero_y(&last, SUNLIT_FOREST, 1));
        }
        assert!(peak > after_jump, "the hero should rise while jumping");
        // Forest ground top is 17_000; the hero settles back onto it.
        assert_eq!(hero_y(&last, SUNLIT_FOREST, 1), 17_000);
    }

    #[test]
    fn walking_into_a_portal_transfers_zones() {
        let mut world = World::default();
        let player = PlayerId::new(1);
        world.join(player, descriptor("Aria")).unwrap();

        let mut transferred = false;
        for tick in 1..250 {
            world.submit_intent(player, intent(tick, 1, false)).unwrap();
            let outcome = world.advance_tick();
            if outcome.transfers.iter().any(|t| t.player_id == player) {
                transferred = true;
                assert_eq!(world.zone_of(player), Some(MOONLIT_MARKET));
                break;
            }
        }
        assert!(transferred, "walking right into the market portal should transfer");
    }

    #[test]
    fn a_human_spawns_in_wendmere_with_npcs_and_enters_the_market() {
        use crate::entity::EntitySnapshot;
        use crate::geometry::{Allegiance, WENDMERE_MARKET, WENDMERE_SQUARE};

        let mut world = World::default();
        let player = PlayerId::new(1);
        let zone = world
            .join(
                player,
                HeroDescriptor {
                    hero_name: "Aldric".to_owned(),
                    lineage: "human".to_owned(),
                    weapon: WeaponId::Sword,
                    allegiance: Allegiance::Light,
                },
            )
            .unwrap();
        assert_eq!(zone, WENDMERE_SQUARE);

        let first = world.advance_tick();
        let square = first
            .snapshots
            .iter()
            .find(|s| s.zone == WENDMERE_SQUARE)
            .unwrap();
        let npcs = square
            .entities
            .iter()
            .filter(|e| matches!(e, EntitySnapshot::Npc(_)))
            .count();
        assert!(npcs >= 3, "expected placeholder NPCs in the square, got {npcs}");

        // Walk right across the plaza to the Market arch (SVG x4860 -> world
        // 486000..510000) and press up to enter it. Manual doors don't fire on
        // contact alone.
        let mut entered = false;
        let mut pos_x = 248_000; // waystone spawn (SVG x2480)
        for tick in 2..400 {
            let at_door = (486_000..=510_000).contains(&pos_x);
            world
                .submit_intent(
                    player,
                    PlayerIntent {
                        sequence: tick,
                        client_tick: tick,
                        move_axis: if at_door { 0 } else { 1 },
                        climb_axis: if at_door { 1 } else { 0 },
                        jump: false,
                        drop: false,
                        guard: false,
                        action_slot: 0,
                    },
                )
                .unwrap();
            let outcome = world.advance_tick();
            if outcome
                .transfers
                .iter()
                .any(|t| t.player_id == player && t.to == WENDMERE_MARKET)
            {
                entered = true;
                break;
            }
            if let Some(square) = outcome.snapshots.iter().find(|s| s.zone == WENDMERE_SQUARE) {
                if let Some(px) = square.entities.iter().find_map(|e| match e {
                    EntitySnapshot::Hero(h) if h.player_id == player => Some(h.position_x),
                    _ => None,
                }) {
                    pos_x = px;
                }
            }
        }
        assert!(entered, "should walk to the Market door and enter it");
    }

    #[test]
    fn a_zone_snapshot_never_shows_another_zones_hero() {
        let mut world = World::default();
        let traveler = PlayerId::new(1);
        let resident = PlayerId::new(2);
        world.join(traveler, descriptor("Traveler")).unwrap();
        world.join(resident, descriptor("Resident")).unwrap();

        // Walk the traveler right into the market portal.
        for tick in 1..250 {
            world.submit_intent(traveler, intent(tick, 1, false)).unwrap();
            world.submit_intent(resident, intent(tick, 0, false)).unwrap();
            let outcome = world.advance_tick();
            if outcome.transfers.iter().any(|t| t.player_id == traveler) {
                break;
            }
        }
        // One more tick to observe the settled arrangement.
        let outcome = world.advance_tick();
        let forest = heroes_in_zone(&outcome, SUNLIT_FOREST);
        let market = heroes_in_zone(&outcome, MOONLIT_MARKET);
        assert!(forest.contains(&2) && !forest.contains(&1), "forest keeps only the resident");
        assert!(market.contains(&1) && !market.contains(&2), "market shows only the traveler");
    }
}
