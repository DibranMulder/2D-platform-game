//! In-memory Account → Hero registry that admits Sessions.
//!
//! This is the foundation's stand-in for a real identity/gateway tier. It has
//! no authentication yet: any account id is accepted, and a hero is created on
//! first sight. What it *does* enforce is the domain rule that matters for a
//! shared world — a Hero is owned by one Account, has a stable identity across
//! reconnects, and can be controlled by only one live Session at a time.

use std::collections::{HashMap, HashSet};

use game_domain::PlayerId;
use game_protocol::JoinRejectionReason;

/// The default Lineage assigned to a freshly provisioned Hero. It is the only
/// id the current client can render; the server owns this value so a later
/// persistence tier can change it without a protocol change.
const DEFAULT_LINEAGE: &str = "human";

/// A successful admission: the stable identity a Session controls this run.
pub struct Admission {
    pub player_id: PlayerId,
    pub hero_name: String,
    pub lineage: String,
}

struct HeroRecord {
    player_id: PlayerId,
    hero_name: String,
    lineage: String,
}

/// Owns the mapping from (account, hero) to a stable [`PlayerId`] and tracks
/// which heroes are currently online. Not `Sync` on its own; the server wraps
/// it in a mutex alongside the world.
#[derive(Default)]
pub struct AccountRegistry {
    heroes: HashMap<(String, String), HeroRecord>,
    online: HashSet<PlayerId>,
    next_id: u64,
}

impl AccountRegistry {
    pub fn new() -> Self {
        Self {
            heroes: HashMap::new(),
            online: HashSet::new(),
            next_id: 0,
        }
    }

    /// Admit an account's hero into the world, creating the hero on first use.
    /// Fails if the identifiers are unusable or the hero is already online.
    pub fn admit(
        &mut self,
        account_id: &str,
        hero_name: &str,
    ) -> Result<Admission, JoinRejectionReason> {
        let account = account_id.trim();
        let hero = hero_name.trim();
        if account.is_empty() || hero.is_empty() {
            return Err(JoinRejectionReason::InvalidHero);
        }

        // Heroes are namespaced under an account and matched case-insensitively
        // so "Aria" and "aria" are the same hero on reconnect. Borrow the id
        // counter separately from the map so the closure touches disjoint fields.
        let key = (account.to_lowercase(), hero.to_lowercase());
        let next_id = &mut self.next_id;
        let record = self.heroes.entry(key).or_insert_with(|| {
            *next_id += 1;
            HeroRecord {
                player_id: PlayerId::new(*next_id),
                hero_name: hero.to_owned(),
                lineage: DEFAULT_LINEAGE.to_owned(),
            }
        });

        if !self.online.insert(record.player_id) {
            return Err(JoinRejectionReason::HeroAlreadyOnline);
        }

        Ok(Admission {
            player_id: record.player_id,
            hero_name: record.hero_name.clone(),
            lineage: record.lineage.clone(),
        })
    }

    /// Mark a hero offline so a future Session may control it again.
    pub fn release(&mut self, player_id: PlayerId) {
        self.online.remove(&player_id);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn same_hero_keeps_a_stable_id_across_reconnects() {
        let mut registry = AccountRegistry::new();
        let first = registry.admit("acct-1", "Aria").unwrap();
        let id = first.player_id;
        registry.release(id);

        let again = registry.admit("acct-1", "  aria  ").unwrap();

        assert_eq!(again.player_id, id);
        assert_eq!(again.hero_name, "Aria");
    }

    #[test]
    fn heroes_under_different_accounts_are_distinct() {
        let mut registry = AccountRegistry::new();
        let a = registry.admit("acct-1", "Aria").unwrap();
        let b = registry.admit("acct-2", "Aria").unwrap();

        assert_ne!(a.player_id, b.player_id);
    }

    #[test]
    fn a_hero_cannot_be_online_twice() {
        let mut registry = AccountRegistry::new();
        registry.admit("acct-1", "Aria").unwrap();

        assert_eq!(
            registry.admit("acct-1", "Aria").err(),
            Some(JoinRejectionReason::HeroAlreadyOnline)
        );
    }

    #[test]
    fn empty_identifiers_are_rejected() {
        let mut registry = AccountRegistry::new();
        assert_eq!(
            registry.admit("", "Aria").err(),
            Some(JoinRejectionReason::InvalidHero)
        );
        assert_eq!(
            registry.admit("acct-1", "   ").err(),
            Some(JoinRejectionReason::InvalidHero)
        );
    }
}
