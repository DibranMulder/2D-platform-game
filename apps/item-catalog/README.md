# The Enchanted Archive · Item Chronicle

A searchable, Hidden-Street-inspired catalogue for curating the game's item
names, art, balance, sources, paper-doll compatibility, review state, and notes.
The checked-in `content/items.json` is the deployable snapshot of the Godot
catalogue at `client/data/items.json`.

## Prerequisites

- Node.js `>=22.13.0`

## Quick Start

```bash
npm install
npm run dev
npm run build
```

This starter does not use `wrangler.jsonc`.

## Included Shape

- `content/items.json`: the hosted item-data snapshot
- `app/` and `components/`: catalogue and curator workspace
- `db/schema.ts`: durable status, notes, and hidden-item flags
- `public/items/`: the approved storybook item-icon family

## Workspace Auth Headers

OpenAI workspace sites can read the current user's email from
`oai-authenticated-user-email`.

SIWC-authenticated workspace sites may also receive
`oai-authenticated-user-full-name` when the user's SIWC profile has a non-empty
`name` claim. The full-name value is percent-encoded UTF-8 and is accompanied by
`oai-authenticated-user-full-name-encoding: percent-encoded-utf-8`.

Treat the full name as optional and fall back to email when it is absent:

```tsx
import { headers } from "next/headers";

export default async function Home() {
  const requestHeaders = await headers();
  const email = requestHeaders.get("oai-authenticated-user-email");
  const encodedFullName = requestHeaders.get("oai-authenticated-user-full-name");
  const fullName =
    encodedFullName &&
    requestHeaders.get("oai-authenticated-user-full-name-encoding") ===
      "percent-encoded-utf-8"
      ? decodeURIComponent(encodedFullName)
      : null;

  const displayName = fullName ?? email;
  // ...
}
```

## Optional Dispatch-Owned ChatGPT Sign-In

Import the ready-to-use helpers from `app/chatgpt-auth.ts` when the site needs
optional or required ChatGPT sign-in:

- Use `getChatGPTUser()` for optional signed-in UI.
- Use `requireChatGPTUser(returnTo)` for server-rendered pages that should send
  anonymous visitors through Sign in with ChatGPT.
- Use `chatGPTSignInPath(returnTo)` and `chatGPTSignOutPath(returnTo)` for
  browser links or actions.
- Pass a same-origin relative `returnTo` path for the destination after sign-in
  or sign-out. The helper validates and safely encodes it.
- Mark protected pages with `export const dynamic = "force-dynamic"` because
  they depend on per-request identity headers.

Dispatch owns `/signin-with-chatgpt`, `/signout-with-chatgpt`, `/callback`, the
OAuth cookies, and identity header injection. Do not implement app routes for
those reserved paths. Routes that do not import and call the helper remain
anonymous-compatible.

SIWC establishes identity only; it does not prove workspace membership. Use the
Sites hosting platform's access policy controls for workspace-wide restrictions,
or enforce explicit server-side membership or allowlist checks.

Use SIWC for account pages, user-specific dashboards, saved records, and write
actions tied to the current ChatGPT user. Leave public content anonymous.

## Useful Commands

- `npm run dev`: start local development
- `npm run build`: verify the vinext build output
- `npm test`: build the starter and verify its rendered loading skeleton
- `npm run catalog:generate`: rebuild the synchronized website and Godot item
  snapshots from `DESIGN-0012` and rebuild the class codex from `DESIGN-0013`
- `npm run db:generate`: generate Drizzle migrations after schema changes

## Curating generated equipment and talents

The catalogue preserves the original prototype records and adds 1,200 generated
class-equipment records: 864 armor pieces and 336 weapons or shields. Generated
items deliberately use `Acquisition not assigned` until shops, quests, recipes,
and creature drop tables are designed. Generic Capes remain independent of
Class armor sets.

The Class Codex contains the six launch Combat Classes and all 108 proposed
Talents. Equipment and Talent review records share the durable curator ledger;
their stable IDs allow approvals and notes to survive catalogue regeneration.

The Creature Bestiary contains the 64 drafted Homeland creatures spanning
Levels 1–40. Its filters distinguish level cohort, Territory, Disposition,
rank, artwork state, and curator review state. The first two cohorts—Levels
1–5 and 6–10—have sixteen generated storybook portraits. Monster review IDs use
the same durable ledger, while item drops and other acquisitions remain
deliberately unassigned.

## Learn More

- [vinext Documentation](https://github.com/cloudflare/vinext)
- [Drizzle D1 Guide](https://orm.drizzle.team/docs/get-started/d1-new)
