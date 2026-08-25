//! Translation between `game-domain` snapshot types and the `game-protocol`
//! wire types. This is the one place the language/authority boundary is crossed.

use game_domain::{
    EnemyKind, EntitySnapshot, WeaponId, ZoneSnapshot, zone_slug,
};
use game_protocol::{
    ServerMessage, WireEnemy, WireEntity, WireHero, WireNpc, WireProjectile, WireWeapon,
};

/// Build a `Snapshot` server message from a domain zone snapshot.
pub fn snapshot_message(snapshot: &ZoneSnapshot) -> ServerMessage {
    ServerMessage::Snapshot {
        server_tick: snapshot.server_tick,
        zone: zone_slug(snapshot.zone).to_owned(),
        entities: snapshot.entities.iter().map(map_entity).collect(),
    }
}

fn map_entity(entity: &EntitySnapshot) -> WireEntity {
    match entity {
        EntitySnapshot::Hero(hero) => WireEntity::Hero(WireHero {
            entity_id: hero.entity_id.0.to_string(),
            player_id: hero.player_id.get().to_string(),
            hero_name: hero.hero_name.clone(),
            lineage: hero.lineage.clone(),
            weapon: weapon_to_wire(hero.weapon),
            position_x: hero.position_x,
            position_y: hero.position_y,
            velocity_x: hero.velocity_x,
            velocity_y: hero.velocity_y,
            facing: hero.facing,
            grounded: hero.grounded,
            climbing: hero.climbing,
            health: hero.health,
            max_health: hero.max_health,
            stamina: hero.stamina,
            mana: hero.mana,
            action_state: hero.action_state.to_owned(),
            last_processed_intent: hero.last_processed_intent,
        }),
        EntitySnapshot::Enemy(enemy) => {
            let wire = WireEnemy {
                entity_id: enemy.entity_id.0.to_string(),
                position_x: enemy.position_x,
                position_y: enemy.position_y,
                velocity_x: enemy.velocity_x,
                velocity_y: enemy.velocity_y,
                facing: enemy.facing,
                health: enemy.health,
                max_health: enemy.max_health,
                ai_state: enemy.ai_state.to_owned(),
                telegraph_ticks: enemy.telegraph_ticks,
            };
            match enemy.kind {
                EnemyKind::Monster => WireEntity::Monster(wire),
                EnemyKind::ButtoncapBiter => WireEntity::Biter(wire),
            }
        }
        EntitySnapshot::Projectile(projectile) => WireEntity::Projectile(WireProjectile {
            entity_id: projectile.entity_id.0.to_string(),
            owner: projectile.owner.get().to_string(),
            kind: projectile.kind.slug().to_owned(),
            position_x: projectile.position_x,
            position_y: projectile.position_y,
            velocity_x: projectile.velocity_x,
            facing: projectile.facing,
        }),
        EntitySnapshot::Npc(npc) => WireEntity::Npc(WireNpc {
            entity_id: npc.entity_id.0.to_string(),
            role: npc.role.clone(),
            name: npc.name.clone(),
            position_x: npc.position_x,
            position_y: npc.position_y,
            facing: npc.facing,
        }),
    }
}

pub fn weapon_from_wire(weapon: WireWeapon) -> WeaponId {
    match weapon {
        WireWeapon::Sword => WeaponId::Sword,
        WireWeapon::AxeShield => WeaponId::AxeShield,
        WireWeapon::Bow => WeaponId::Bow,
        WireWeapon::Staff => WeaponId::Staff,
        WireWeapon::Wand => WeaponId::Wand,
    }
}

fn weapon_to_wire(weapon: WeaponId) -> WireWeapon {
    match weapon {
        WeaponId::Sword => WireWeapon::Sword,
        WeaponId::AxeShield => WireWeapon::AxeShield,
        WeaponId::Bow => WireWeapon::Bow,
        WeaponId::Staff => WireWeapon::Staff,
        WeaponId::Wand => WireWeapon::Wand,
    }
}
