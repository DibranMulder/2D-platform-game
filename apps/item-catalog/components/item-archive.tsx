"use client";
/* Static catalogue icons deliberately bypass the hosted image transformer. */
/* eslint-disable @next/next/no-img-element */

import { useEffect, useMemo, useState } from "react";

export type Item = {
  id: string; name: string; category: string; slot: string; weapon_family: string;
  grip: string; offhand_compatible: boolean; quality: string; level: number; price: number;
  icon: string; icon_path: string; description: string; stats: Record<string, number>;
  body_families: string[]; source: string; tags: string[]; art_status: string; sprite_status: string;
};

type Review = { itemId: string; status: string; notes: string; hidden: boolean; updatedAt?: string };

const statusLabels: Record<string, string> = {
  unreviewed: "Unreviewed", "needs-work": "Needs work", approved: "Approved", rejected: "Rejected",
};

function humanize(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (character) => character.toUpperCase());
}

function searchText(item: Item) {
  return [item.id, item.name, item.category, item.slot, item.weapon_family, item.source, ...item.tags].join(" ").toLowerCase();
}

export function ItemArchive({ items }: { items: Item[] }) {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("all");
  const [quality, setQuality] = useState("all");
  const [reviewFilter, setReviewFilter] = useState("all");
  const [selectedId, setSelectedId] = useState(items[0]?.id ?? "");
  const [reviews, setReviews] = useState<Record<string, Review>>({});
  const [saveState, setSaveState] = useState("Ready");
  const [persistent, setPersistent] = useState(true);

  useEffect(() => {
    fetch("/api/reviews")
      .then((response) => response.json())
      .then((payload) => {
        const next: Record<string, Review> = {};
        for (const review of payload.reviews ?? []) next[review.itemId] = review;
        setReviews(next);
        setPersistent(Boolean(payload.persistent));
      })
      .catch(() => setPersistent(false));
  }, []);

  const getReview = (itemId: string): Review =>
    reviews[itemId] ?? { itemId, status: "unreviewed", notes: "", hidden: false };

  const filteredItems = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return items.filter((item) =>
      (!needle || searchText(item).includes(needle)) &&
      (category === "all" || item.category === category) &&
      (quality === "all" || item.quality === quality) &&
      (reviewFilter === "all" || (reviews[item.id]?.status ?? "unreviewed") === reviewFilter),
    );
  }, [items, query, category, quality, reviewFilter, reviews]);

  const selected = items.find((item) => item.id === selectedId) ?? filteredItems[0] ?? items[0];
  const selectedReview = selected ? getReview(selected.id) : null;
  const approvedCount = Object.values(reviews).filter((review) => review.status === "approved").length;
  const needsWorkCount = Object.values(reviews).filter((review) => review.status === "needs-work").length;

  function patchReview(itemId: string, patch: Partial<Review>) {
    setReviews((current) => ({ ...current, [itemId]: { ...getReview(itemId), ...patch } }));
    setSaveState("Unsaved changes");
  }

  async function saveReview() {
    if (!selectedReview) return;
    setSaveState("Saving…");
    const response = await fetch("/api/reviews", {
      method: "PUT", headers: { "content-type": "application/json" }, body: JSON.stringify(selectedReview),
    });
    if (!response.ok) { setSaveState("Could not save"); return; }
    const payload = await response.json();
    setReviews((current) => ({ ...current, [selectedReview.itemId]: payload.review }));
    setSaveState("Saved");
  }

  return (
    <main className="archive-shell">
      <header className="masthead">
        <div className="brand-mark" aria-hidden="true">EA</div>
        <div className="brand-copy">
          <p className="eyebrow">The Enchanted Archive</p>
          <h1>Item Chronicle</h1>
          <p>Every blade, boot, bauble, and secret worth finding.</p>
        </div>
        <div className="archive-tally"><strong>{items.length}</strong><span>known items</span></div>
      </header>

      <section className="tool-ribbon" aria-label="Catalogue controls">
        <label className="search-box"><span>Search the archive</span><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Name, source, weapon family…" /></label>
        <div className="summary-chip"><b>{approvedCount}</b> approved</div>
        <div className="summary-chip warning"><b>{needsWorkCount}</b> needs work</div>
        <div className={`storage-chip ${persistent ? "online" : "offline"}`}>{persistent ? "Curator ledger connected" : "Preview ledger unavailable"}</div>
      </section>

      <div className="archive-layout">
        <aside className="filter-rail">
          <p className="section-kicker">Browse shelves</p>
          <FilterGroup title="Item type" value={category} onChange={setCategory} options={["all", ...new Set(items.map((item) => item.category))]} />
          <FilterGroup title="Rarity" value={quality} onChange={setQuality} options={["all", "common", "uncommon", "rare", "epic"]} />
          <FilterGroup title="Review" value={reviewFilter} onChange={setReviewFilter} options={["all", "unreviewed", "needs-work", "approved", "rejected"]} labels={statusLabels} />
          <div className="legend"><p className="section-kicker">Paper-doll rule</p><p>Equipment art is layered over a shared body animation. One-handed weapons may pair with a shield; two-handed weapons reserve both hands.</p></div>
        </aside>

        <section className="item-library">
          <div className="library-heading"><div><p className="section-kicker">Chronicle entries</p><h2>{filteredItems.length} items found</h2></div><span>Click an item to curate it</span></div>
          <div className="item-grid">
            {filteredItems.map((item) => {
              const review = getReview(item.id);
              return (
                <button className={`item-card ${selected?.id === item.id ? "selected" : ""}`} key={item.id} onClick={() => { setSelectedId(item.id); setSaveState("Ready"); }}>
                  <span className={`rarity-bar ${item.quality}`} />
                  <img src={item.icon_path} alt="" width={72} height={72} />
                  <span className="item-card-copy"><small>{humanize(item.category)} · Lv. {item.level}</small><strong>{item.name}</strong><em>{item.source}</em></span>
                  <span className={`review-dot ${review.status}`} title={statusLabels[review.status]} />
                </button>
              );
            })}
          </div>
          {filteredItems.length === 0 && <div className="empty-state">No chronicle entry matches those filters.</div>}
        </section>

        {selected && selectedReview && (
          <aside className="curator-panel">
            <div className={`hero-icon ${selected.quality}`}><img src={selected.icon_path} alt={selected.name} width={112} height={112} /></div>
            <p className="item-id">{selected.id}</p><h2>{selected.name}</h2><p className="item-description">{selected.description}</p>
            <dl className="facts">
              <div><dt>Type</dt><dd>{humanize(selected.category)}</dd></div><div><dt>Slot</dt><dd>{selected.slot ? humanize(selected.slot) : "Inventory"}</dd></div>
              <div><dt>Rarity</dt><dd className={selected.quality}>{humanize(selected.quality)}</dd></div><div><dt>Price</dt><dd>{selected.price} gold</dd></div>
              {selected.weapon_family && <div><dt>Family</dt><dd>{humanize(selected.weapon_family)}</dd></div>}{selected.grip && <div><dt>Grip</dt><dd>{humanize(selected.grip)}</dd></div>}
            </dl>
            <div className="stats-block"><p className="section-kicker">Game effects</p>{Object.keys(selected.stats).length ? Object.entries(selected.stats).map(([name, value]) => <span key={name}>{humanize(name)} <b>{value > 0 ? "+" : ""}{value}</b></span>) : <span>Crafting material · no direct stat</span>}</div>
            <div className="compatibility"><p className="section-kicker">Body compatibility</p>{selected.body_families.map((family) => <span key={family}>{humanize(family)}</span>)}</div>
            <div className="curator-form">
              <p className="section-kicker">Curator ledger</p>
              <label>Status<select value={selectedReview.status} onChange={(event) => patchReview(selected.id, { status: event.target.value })}>{Object.entries(statusLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
              <label>Notes<textarea value={selectedReview.notes} onChange={(event) => patchReview(selected.id, { notes: event.target.value })} placeholder="Shape, colors, balance, drop location, naming…" /></label>
              <label className="check-row"><input type="checkbox" checked={selectedReview.hidden} onChange={(event) => patchReview(selected.id, { hidden: event.target.checked })} />Hidden or secret item</label>
              <button className="save-button" onClick={saveReview}>Save to curator ledger</button><span className="save-state">{saveState}</span>
            </div>
          </aside>
        )}
      </div>
    </main>
  );
}

function FilterGroup({ title, value, onChange, options, labels = {} }: { title: string; value: string; onChange: (value: string) => void; options: string[]; labels?: Record<string, string> }) {
  return <fieldset className="filter-group"><legend>{title}</legend>{options.map((option) => <button className={value === option ? "active" : ""} onClick={() => onChange(option)} key={option}>{labels[option] ?? humanize(option)}</button>)}</fieldset>;
}
