---
id: DESIGN-0003
title: Security and anti-cheat
status: initial-threat-model
updated: 2026-08-22
---

# Security and anti-cheat

Anti-cheat is primarily an authoritative-system design problem. Client hardening
raises attacker cost but is never treated as proof that client data is honest.

## Trust model

| Asset or claim | Authority | Client treatment |
| --- | --- | --- |
| Position and velocity | World Instance | Client sends directional Intent only |
| Hit, damage, cooldown | World Instance | Client may predict visuals, never results |
| Inventory, currency, drops | Durable backend | Client displays signed-in account state |
| Skill XP and levels | Durable backend | Awarded from validated server events |
| Trading and marketplace | Durable backend | Atomic, idempotent server transaction |
| Local animation and effects | Client | Untrusted and cosmetic |

## Threats and foundation controls

| Threat | Foundation control | Later control |
| --- | --- | --- |
| Speed/teleport | Server integrates movement; no position message exists | Movement anomaly telemetry and lag-compensation bounds |
| Input flood | Message-size and per-session rate limits | Edge throttling and adaptive sanctions |
| Replay/reorder | Monotonic Intent sequence per Session | Session nonce and authenticated packet sequence |
| Protocol abuse | Version gate and strict tagged messages | Fuzzing, schema compatibility tests, WAF rules |
| Memory/binary modification | No valuable truth resides only in the client | Signing, integrity attestation where useful, obfuscation as delay only |
| Botting | Server-side cadence and behavior evidence | Detection pipeline, challenge strategy, reviewed sanctions |
| Item/currency duplication | Not yet implemented | Idempotency keys, atomic ledger, invariant audits |
| Credential/session theft | Development handshake is explicitly insecure | OIDC identity, short-lived admission token, TLS, rotation/revocation |
| Admin abuse | No admin surface exists | Least privilege, hardware-backed MFA, immutable audit trail |

## Enforcement principles

- Reject impossible actions at the owning rule, not in UI code.
- Distinguish malformed, impossible, suspicious, and proven-abusive behavior.
- Record security evidence before applying irreversible sanctions.
- Never ship detection thresholds or secrets as the sole control in the client.
- Keep false-positive review and appeal possible.
- Minimize collected personal data and define retention before telemetry launch.

## Current security limitations

The bootstrap endpoint is plaintext local WebSocket with a development-only
handshake, no account identity, no TLS, no durable audit sink, and in-memory
state. It must not be exposed to the public internet. These gaps are explicit so
the prototype cannot be mistaken for a launch configuration.

## Security gates

1. **Before remote team testing:** TLS termination, real identity, short-lived
   Session admission, structured audit events, dependency scanning.
2. **Before persistent economy:** transactional ledger, idempotency, reconciliation,
   privileged-action audit, backup/restore exercises.
3. **Before public testing:** load and protocol fuzz tests, detection telemetry,
   incident response, moderation tools, rate limits at the edge.
4. **Before release:** platform signing, supply-chain provenance, privacy review,
   penetration test, red-team economy and conflict exploits.

## Change log

- 2026-08-22: Initial assets, threats, controls, and release gates recorded.

