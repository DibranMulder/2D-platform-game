# Design Record Index

Every design record has a status and is expected to change through review. The
records separate settled constraints from later creative decisions so races,
themes, and content can be added without reshaping the runtime.

| Record | Status | Purpose |
| --- | --- | --- |
| [Product constraints](0001-product-constraints.md) | Accepted foundation | Scope and non-negotiable platform qualities |
| [System architecture](0002-system-architecture.md) | Accepted foundation | Runtime shape, module seams, and data flow |
| [Security and anti-cheat](0003-security-and-anti-cheat.md) | Initial threat model | Trust model, controls, and staged protections |
| [Delivery roadmap](0004-delivery-roadmap.md) | Proposed | Thin vertical slices toward production |
| [Combat mechanics prototype](0005-combat-mechanics-prototype.md) | Exploring | Static arena controls, moves, skills, and evaluation questions |

Durable decisions whose reversal would be expensive are recorded separately in
[`docs/adr`](../adr/). Project-specific terminology is defined in
[`CONTEXT.md`](../../CONTEXT.md).

## Update rule

When a requirement changes, update its design record and add a dated entry to
the record's change log. If the change reverses an ADR, add a superseding ADR;
do not rewrite history.
