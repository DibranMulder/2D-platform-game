import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const root = new URL("../", import.meta.url);

test("catalogue contains unique, complete item records", async () => {
  const catalog = JSON.parse(await readFile(new URL("content/items.json", root), "utf8"));
  assert.ok(catalog.items.length >= 20);
  assert.equal(new Set(catalog.items.map((item) => item.id)).size, catalog.items.length);
  for (const item of catalog.items) {
    assert.ok(item.id && item.name && item.category && item.quality);
    assert.match(item.icon_path, /^\/items\/(?:icon-\d{2}|generated\/[a-z0-9_\/-]+)\.png$/);
  }
});

test("generated class equipment matches the accepted design scale", async () => {
  const catalog = JSON.parse(await readFile(new URL("content/items.json", root), "utf8"));
  const generated = catalog.items.filter((item) => item.design_origin === "design-0012");
  const armor = generated.filter((item) => item.category === "armor");
  const weapons = generated.filter((item) => item.category === "weapon" || item.category === "shield");
  assert.equal(generated.length, 1200);
  assert.equal(armor.length, 864);
  assert.equal(weapons.length, 336);
  assert.deepEqual(new Set(generated.map((item) => item.tier)), new Set(Array.from({ length: 12 }, (_, index) => index + 1)));
  assert.equal(generated.some((item) => item.category === "cape"), false);
  assert.ok(generated.every((item) => item.source === "Acquisition not assigned"));
});

test("generated item artwork is present and refined records reuse it explicitly", async () => {
  const catalog = JSON.parse(await readFile(new URL("content/items.json", root), "utf8"));
  const completed = catalog.items.filter((item) => item.design_origin === "design-0012" && item.art_status === "generated");
  const reused = catalog.items.filter((item) => item.design_origin === "design-0012" && item.art_status === "refined-variant-needed");
  assert.equal(completed.length, 9);
  assert.equal(reused.length, 9);
  await Promise.all(completed.map((item) => access(new URL(`public${item.icon_path}`, root))));
});

test("class codex contains six complete distinct talent trees", async () => {
  const catalog = JSON.parse(await readFile(new URL("content/classes.json", root), "utf8"));
  assert.equal(catalog.classes.length, 6);
  assert.ok(catalog.classes.every((entry) => entry.branches.length === 3));
  assert.ok(catalog.classes.every((entry) => entry.branches.every((branch) => branch.talents.length === 6)));
  const talents = catalog.classes.flatMap((entry) => entry.branches.flatMap((branch) => branch.talents));
  assert.equal(talents.length, 108);
  assert.equal(new Set(talents.map((talent) => talent.id)).size, 108);
  assert.deepEqual(catalog.classes.find((entry) => entry.id === "duelist").weapons, ["One-Handed Sword", "One-Handed Axe", "Dagger"]);
  assert.deepEqual(catalog.classes.find((entry) => entry.id === "warden").branches.map((branch) => branch.name), ["Radiance", "Gloam", "Eclipse"]);
});

test("bestiary contains all drafted level 1–40 creatures and first-cohort artwork", async () => {
  const catalog = JSON.parse(await readFile(new URL("content/monsters.json", root), "utf8"));
  assert.equal(catalog.monsters.length, 64);
  assert.equal(new Set(catalog.monsters.map((monster) => monster.id)).size, 64);
  for (let cohort = 1; cohort <= 8; cohort += 1) {
    assert.equal(catalog.monsters.filter((monster) => monster.cohort === cohort).length, 8);
  }
  const illustrated = catalog.monsters.filter((monster) => monster.art_status === "generated");
  assert.equal(illustrated.length, 16);
  assert.ok(illustrated.every((monster) => monster.level_end <= 10));
  await Promise.all(illustrated.map((monster) => access(new URL(`public${monster.image_path}`, root))));
});

test("hosted and Godot item snapshots remain synchronized", async () => {
  const [hosted, godot] = await Promise.all([
    readFile(new URL("content/items.json", root), "utf8"),
    readFile(new URL("../../client/data/items.json", root), "utf8"),
  ]);
  assert.equal(hosted, godot);
});

test("site is free of starter preview metadata", async () => {
  const [page, layout] = await Promise.all([
    readFile(new URL("app/page.tsx", root), "utf8"),
    readFile(new URL("app/layout.tsx", root), "utf8"),
  ]);
  assert.doesNotMatch(page + layout, /codex-preview|SkeletonPreview|Starter Project/);
  assert.match(layout, /Item Chronicle/);
});

test("item icons bypass the width-restricted image transformer", async () => {
  const component = await readFile(new URL("components/item-archive.tsx", root), "utf8");
  assert.doesNotMatch(component, /from ["']next\/image["']/);
  assert.match(component, /<img src=\{item\.icon_path\}/);
  assert.match(component, /<img src=\{selected\.icon_path\}/);
});

test("monster portraits bypass the image transformer", async () => {
  const component = await readFile(new URL("components/monster-bestiary.tsx", root), "utf8");
  assert.doesNotMatch(component, /from ["']next\/image["']/);
  assert.match(component, /<img src=\{monster\.image_path\}/);
  assert.match(component, /<img src=\{selected\.image_path\}/);
});
