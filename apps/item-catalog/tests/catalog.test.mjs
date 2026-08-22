import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const root = new URL("../", import.meta.url);

test("catalogue contains unique, complete item records", async () => {
  const catalog = JSON.parse(await readFile(new URL("content/items.json", root), "utf8"));
  assert.ok(catalog.items.length >= 20);
  assert.equal(new Set(catalog.items.map((item) => item.id)).size, catalog.items.length);
  for (const item of catalog.items) {
    assert.ok(item.id && item.name && item.category && item.quality);
    assert.match(item.icon_path, /^\/items\/icon-\d{2}\.png$/);
  }
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
