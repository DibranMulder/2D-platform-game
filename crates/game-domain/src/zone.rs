//! One map's live simulation: its geometry plus every entity currently in it.
//! A [`crate::world::World`] owns several zones and advances each one per tick.

use std::collections::BTreeMap;

use crate::combat::strike_hits;
use crate::entity::{
    EnemySnapshot, EntityId, EntitySnapshot, HeroSnapshot, NpcSnapshot, ProjectileSnapshot,
    ZoneSnapshot,
};
use crate::enemy::Enemy;
use crate::geometry::{NpcSpawn, SpawnId, ZoneGeometry, ZoneId};
use crate::hero::{Hero, HeroEffect};
use crate::intent::{IntentError, PlayerIntent};
use crate::projectile::{PROJECTILE_HALF_WIDTH, PROJECTILE_LIFETIME, PROJECTILE_VERTICAL, Projectile};
use crate::PlayerId;

const ENEMY_ID_BASE: u64 = 1_000_000;
const PROJECTILE_ID_BASE: u64 = 2_000_000;
const NPC_ID_BASE: u64 = 3_000_000;
const PORTAL_COOLDOWN: u16 = 13; // ~0.65s, matches the prototype portal lock

/// A hero that walked into a portal this tick and must move to another zone.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PortalCross {
    pub player_id: PlayerId,
    pub target: ZoneId,
    pub target_spawn: SpawnId,
}

pub struct Zone {
    geom: ZoneGeometry,
    heroes: BTreeMap<PlayerId, Hero>,
    enemies: BTreeMap<EntityId, Enemy>,
    projectiles: Vec<Projectile>,
    npcs: Vec<(EntityId, NpcSpawn)>,
    next_projectile: u64,
}

impl Zone {
    pub fn new(geom: ZoneGeometry) -> Self {
        let mut enemies = BTreeMap::new();
        for (index, spawn) in geom.enemy_spawns.iter().enumerate() {
            let id = EntityId(ENEMY_ID_BASE + index as u64);
            enemies.insert(id, Enemy::from_spawn(id, *spawn));
        }
        let npcs = geom
            .npc_spawns
            .iter()
            .enumerate()
            .map(|(index, spawn)| (EntityId(NPC_ID_BASE + index as u64), *spawn))
            .collect();
        Self {
            geom,
            heroes: BTreeMap::new(),
            enemies,
            projectiles: Vec::new(),
            npcs,
            next_projectile: 0,
        }
    }

    pub fn id(&self) -> ZoneId {
        self.geom.id
    }

    pub fn geometry(&self) -> &ZoneGeometry {
        &self.geom
    }

    pub fn is_empty(&self) -> bool {
        self.heroes.is_empty()
    }

    pub fn contains_hero(&self, id: PlayerId) -> bool {
        self.heroes.contains_key(&id)
    }

    pub fn insert_hero(&mut self, hero: Hero) {
        self.heroes.insert(hero.player_id, hero);
    }

    pub fn remove_hero(&mut self, id: PlayerId) -> Option<Hero> {
        // A departing hero's in-flight projectiles are dropped with them.
        self.projectiles.retain(|projectile| projectile.owner != id);
        self.heroes.remove(&id)
    }

    pub fn set_hero_weapon(&mut self, id: PlayerId, weapon: crate::hero::WeaponId) -> bool {
        match self.heroes.get_mut(&id) {
            Some(hero) => {
                hero.set_weapon(weapon);
                true
            }
            None => false,
        }
    }

    pub fn submit_intent(
        &mut self,
        id: PlayerId,
        intent: PlayerIntent,
    ) -> Result<(), IntentError> {
        self.heroes
            .get_mut(&id)
            .ok_or(IntentError::UnknownPlayer)?
            .apply_intent(intent)
    }

    /// Advance every entity one tick and return this zone's snapshot plus any
    /// heroes that crossed into a portal (the world performs the handoff).
    pub fn advance_tick(&mut self, server_tick: u64) -> (ZoneSnapshot, Vec<PortalCross>) {
        // 1. Heroes move and emit combat effects.
        let mut effects: Vec<(PlayerId, HeroEffect)> = Vec::new();
        for (id, hero) in &mut self.heroes {
            for effect in hero.advance(&self.geom) {
                effects.push((*id, effect));
            }
        }

        // 2. Resolve hero effects against enemies.
        for (owner, effect) in effects {
            match effect {
                HeroEffect::Melee {
                    damage,
                    reach,
                    vertical,
                    omni,
                    stagger_ticks,
                    x,
                    y,
                    facing,
                } => {
                    if let Some(target) = self.nearest_enemy_in_strike(x, y, facing, reach, vertical, omni) {
                        if let Some(enemy) = self.enemies.get_mut(&target) {
                            enemy.receive_damage(damage);
                            if stagger_ticks > 0 {
                                enemy.apply_stagger(stagger_ticks);
                            }
                        }
                    }
                }
                HeroEffect::SpawnProjectiles {
                    spec,
                    x,
                    y,
                    facing,
                } => {
                    for offset in spec.height_offsets {
                        let id = EntityId(PROJECTILE_ID_BASE + self.next_projectile);
                        self.next_projectile += 1;
                        self.projectiles.push(Projectile {
                            id,
                            owner,
                            kind: spec.kind,
                            pos_x: x,
                            pos_y: y + offset,
                            vel_x: facing as i32 * spec.speed,
                            facing,
                            damage: spec.damage,
                            remaining: PROJECTILE_LIFETIME,
                            spent: false,
                        });
                    }
                }
            }
        }

        // 3. Enemies act against heroes.
        let mut damage_requests = Vec::new();
        for enemy in self.enemies.values_mut() {
            damage_requests.extend(enemy.advance(&self.heroes, &self.geom));
        }
        for request in damage_requests {
            if let Some(hero) = self.heroes.get_mut(&request.target) {
                hero.receive_damage(request.amount, request.attacker_x);
            }
        }

        // 4. Projectiles move and strike enemies (swept along x).
        self.advance_projectiles();

        // 5. Portal detection.
        let crosses = self.detect_portal_crosses();

        (self.snapshot(server_tick), crosses)
    }

    fn nearest_enemy_in_strike(
        &self,
        x: i32,
        y: i32,
        facing: i8,
        reach: i32,
        vertical: i32,
        omni: bool,
    ) -> Option<EntityId> {
        self.enemies
            .values()
            .filter(|enemy| enemy.is_alive())
            .filter(|enemy| {
                strike_hits(x, y, facing, enemy.pos_x, enemy.pos_y, reach, vertical, omni)
            })
            .min_by_key(|enemy| (enemy.pos_x - x).abs())
            .map(|enemy| enemy.id)
    }

    fn advance_projectiles(&mut self) {
        for projectile in &mut self.projectiles {
            let prev_x = projectile.advance(self.geom.min_x, self.geom.max_x);
            if projectile.spent {
                continue;
            }
            let lo = prev_x.min(projectile.pos_x) - PROJECTILE_HALF_WIDTH;
            let hi = prev_x.max(projectile.pos_x) + PROJECTILE_HALF_WIDTH;
            let mut best: Option<EntityId> = None;
            let mut best_dist = i32::MAX;
            for enemy in self.enemies.values() {
                if !enemy.is_alive() {
                    continue;
                }
                if enemy.pos_x >= lo
                    && enemy.pos_x <= hi
                    && (enemy.pos_y - projectile.pos_y).abs() <= PROJECTILE_VERTICAL
                {
                    let dist = (enemy.pos_x - prev_x).abs();
                    if dist < best_dist {
                        best_dist = dist;
                        best = Some(enemy.id);
                    }
                }
            }
            if let Some(target) = best {
                if let Some(enemy) = self.enemies.get_mut(&target) {
                    enemy.receive_damage(projectile.damage);
                }
                projectile.spent = true;
            }
        }
        self.projectiles.retain(|projectile| !projectile.spent);
    }

    fn detect_portal_crosses(&mut self) -> Vec<PortalCross> {
        let mut crosses = Vec::new();
        for hero in self.heroes.values_mut() {
            if hero.portal_cooldown > 0 || !hero.is_alive() {
                continue;
            }
            for portal in &self.geom.portals {
                if portal.bounds.contains(hero.pos_x, hero.pos_y) {
                    // Manual town doors only fire when the Hero presses up, so
                    // hub rooms with several doors are unambiguous.
                    if portal.manual && !hero.interacting() {
                        continue;
                    }
                    // Allegiance gate: an opposing-Allegiance Hero is repelled
                    // (nudged back) and does not cross (DESIGN-0009).
                    if let Some(required) = portal.required_allegiance {
                        if hero.descriptor.allegiance != required {
                            hero.portal_cooldown = PORTAL_COOLDOWN;
                            hero.vel_x = -hero.facing as i32 * crate::fixed::HERO_MOVE_SPEED;
                            break;
                        }
                    }
                    hero.portal_cooldown = PORTAL_COOLDOWN;
                    crosses.push(PortalCross {
                        player_id: hero.player_id,
                        target: portal.target,
                        target_spawn: portal.target_spawn,
                    });
                    break;
                }
            }
        }
        crosses
    }

    pub fn snapshot(&self, server_tick: u64) -> ZoneSnapshot {
        let mut entities = Vec::new();
        for hero in self.heroes.values() {
            entities.push(EntitySnapshot::Hero(HeroSnapshot {
                entity_id: EntityId(hero.player_id.get()),
                player_id: hero.player_id,
                hero_name: hero.descriptor.hero_name.clone(),
                lineage: hero.descriptor.lineage.clone(),
                weapon: hero.descriptor.weapon,
                position_x: hero.pos_x,
                position_y: hero.pos_y,
                velocity_x: hero.vel_x,
                velocity_y: hero.vel_y,
                facing: hero.facing,
                grounded: hero.grounded,
                climbing: hero.climbing.is_some(),
                health: hero.health,
                max_health: crate::hero::MAX_HEALTH,
                stamina: hero.stamina_milli / 1_000,
                mana: hero.mana_milli / 1_000,
                action_state: hero.current_action,
                last_processed_intent: hero.last_processed_intent,
            }));
        }
        for enemy in self.enemies.values() {
            entities.push(EntitySnapshot::Enemy(EnemySnapshot {
                entity_id: enemy.id,
                kind: enemy.kind,
                position_x: enemy.pos_x,
                position_y: enemy.pos_y,
                velocity_x: enemy.vel_x,
                velocity_y: enemy.vel_y,
                facing: enemy.facing,
                health: enemy.health,
                max_health: enemy.max_health,
                ai_state: enemy.ai_state(),
                telegraph_ticks: enemy.telegraph_ticks(),
            }));
        }
        for projectile in &self.projectiles {
            entities.push(EntitySnapshot::Projectile(ProjectileSnapshot {
                entity_id: projectile.id,
                owner: projectile.owner,
                kind: projectile.kind,
                position_x: projectile.pos_x,
                position_y: projectile.pos_y,
                velocity_x: projectile.vel_x,
                facing: projectile.facing,
            }));
        }
        for (id, npc) in &self.npcs {
            entities.push(EntitySnapshot::Npc(NpcSnapshot {
                entity_id: *id,
                role: npc.role.to_owned(),
                name: npc.name.to_owned(),
                position_x: npc.x,
                position_y: npc.y,
                facing: npc.facing,
            }));
        }
        ZoneSnapshot {
            zone: self.geom.id,
            server_tick,
            entities,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::geometry::{
        ClimbKind, ClimbVolume, EnemyKind, EnemySpawn, OneWayPlatform, SUNLIT_FOREST, SpawnId,
        SpawnPoint,
    };
    use crate::hero::{Hero, HeroDescriptor, WeaponId};

    fn descriptor(weapon: WeaponId) -> HeroDescriptor {
        HeroDescriptor {
            hero_name: "Test".to_owned(),
            lineage: "human".to_owned(),
            weapon,
            allegiance: crate::geometry::Allegiance::Light,
        }
    }

    fn intent(sequence: u64, move_axis: i8, climb_axis: i8, jump: bool, action_slot: u8) -> PlayerIntent {
        PlayerIntent {
            sequence,
            client_tick: sequence,
            move_axis,
            climb_axis,
            jump,
            drop: false,
            guard: false,
            action_slot,
        }
    }

    fn bare_geometry() -> ZoneGeometry {
        ZoneGeometry {
            id: SUNLIT_FOREST,
            ground_top_y: 0,
            min_x: -100_000,
            max_x: 100_000,
            solids: Vec::new(),
            one_ways: Vec::new(),
            climbs: Vec::new(),
            portals: Vec::new(),
            spawns: vec![SpawnPoint {
                id: SpawnId(0),
                x: 0,
                y: 0,
                facing: 1,
            }],
            enemy_spawns: Vec::new(),
            npc_spawns: Vec::new(),
        }
    }

    fn spawn_at(x: i32, y: i32) -> SpawnPoint {
        SpawnPoint {
            id: SpawnId(0),
            x,
            y,
            facing: 1,
        }
    }

    fn enemy_health(zone: &Zone, id: EntityId) -> i32 {
        zone.enemies.get(&id).map(|e| e.health).unwrap_or(-1)
    }

    #[test]
    fn hero_falls_and_lands_on_a_one_way_platform_while_descending() {
        let mut geom = bare_geometry();
        geom.one_ways.push(OneWayPlatform {
            top_y: 5_000,
            min_x: -5_000,
            max_x: 5_000,
        });
        let mut zone = Zone::new(geom);
        let mut hero = Hero::new(PlayerId::new(1), descriptor(WeaponId::Sword), spawn_at(0, 8_000));
        hero.grounded = false;
        zone.insert_hero(hero);

        for tick in 1..40 {
            zone.submit_intent(PlayerId::new(1), intent(tick, 0, 0, false, 0)).unwrap();
            zone.advance_tick(tick);
        }
        let snapshot = zone.snapshot(99);
        let hero = snapshot
            .entities
            .iter()
            .find_map(|e| match e {
                EntitySnapshot::Hero(h) => Some(h),
                _ => None,
            })
            .unwrap();
        assert_eq!(hero.position_y, 5_000, "should rest on the one-way platform top");
        assert!(hero.grounded);
    }

    #[test]
    fn hero_climbs_a_ladder_upward() {
        let mut geom = bare_geometry();
        geom.climbs.push(ClimbVolume {
            center_x: 0,
            top_exit_y: 10_000,
            bottom_exit_y: 0,
            kind: ClimbKind::Ladder,
        });
        let mut zone = Zone::new(geom);
        zone.insert_hero(Hero::new(PlayerId::new(1), descriptor(WeaponId::Sword), spawn_at(0, 0)));

        let mut last_y = 0;
        for tick in 1..12 {
            zone.submit_intent(PlayerId::new(1), intent(tick, 0, 1, false, 0)).unwrap();
            zone.advance_tick(tick);
            let y = zone.snapshot(tick).entities.iter().find_map(|e| match e {
                EntitySnapshot::Hero(h) => Some(h.position_y),
                _ => None,
            }).unwrap();
            assert!(y >= last_y, "climbing up must not descend");
            last_y = y;
        }
        assert!(last_y >= 9_000, "hero should climb near the top exit, got {last_y}");
    }

    #[test]
    fn sword_strike_damages_the_nearest_enemy_in_reach() {
        let mut geom = bare_geometry();
        geom.enemy_spawns.push(EnemySpawn {
            kind: EnemyKind::ButtoncapBiter,
            x: 3_000,
            y: 0,
            patrol_min_x: 2_000,
            patrol_max_x: 4_000,
            facing: 1,
        });
        let mut zone = Zone::new(geom);
        let enemy_id = EntityId(1_000_000);
        zone.insert_hero(Hero::new(PlayerId::new(1), descriptor(WeaponId::Sword), spawn_at(0, 0)));

        let before = enemy_health(&zone, enemy_id);
        zone.submit_intent(PlayerId::new(1), intent(1, 0, 0, false, 1)).unwrap();
        zone.advance_tick(1);
        let after = enemy_health(&zone, enemy_id);
        assert!(after < before, "sword attack should damage the biter ({before} -> {after})");
    }

    #[test]
    fn a_biter_in_contact_damages_the_hero() {
        let mut geom = bare_geometry();
        geom.enemy_spawns.push(EnemySpawn {
            kind: EnemyKind::ButtoncapBiter,
            x: 0,
            y: 0,
            patrol_min_x: -2_000,
            patrol_max_x: 2_000,
            facing: 1,
        });
        let mut zone = Zone::new(geom);
        zone.insert_hero(Hero::new(PlayerId::new(1), descriptor(WeaponId::Sword), spawn_at(0, 0)));

        zone.advance_tick(1);
        let health = zone.snapshot(1).entities.iter().find_map(|e| match e {
            EntitySnapshot::Hero(h) => Some(h.health),
            _ => None,
        }).unwrap();
        assert!(health < 100, "a biter sharing the hero's tile should deal contact damage");
    }
}
