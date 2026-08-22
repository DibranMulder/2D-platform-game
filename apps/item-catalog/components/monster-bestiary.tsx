"use client";
/* Static bestiary portraits deliberately bypass the hosted image transformer. */
/* eslint-disable @next/next/no-img-element */

import { useEffect, useMemo, useState } from "react";

export type Monster = {
  id: string;
  name: string;
  level_start: number;
  level_end: number;
  cohort: number;
  territory: string;
  terrain: string;
  disposition: string;
  rank: string;
  gameplay_identity: string;
  art_status: string;
  image_path: string;
  source_doc: string;
};

type Review = { itemId: string; status: string; notes: string; hidden: boolean; updatedAt?: string };

const statusLabels: Record<string, string> = {
  unreviewed: "Unreviewed",
  "needs-work": "Needs work",
  approved: "Approved",
  rejected: "Rejected",
};

function humanize(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (character) => character.toUpperCase());
}

export function MonsterBestiary({ monsters, onShowItems, onShowTalents }: { monsters: Monster[]; onShowItems: () => void; onShowTalents: () => void }) {
  const [query, setQuery] = useState("");
  const [cohort, setCohort] = useState("all");
  const [territory, setTerritory] = useState("all");
  const [disposition, setDisposition] = useState("all");
  const [rank, setRank] = useState("all");
  const [artStatus, setArtStatus] = useState("all");
  const [reviewFilter, setReviewFilter] = useState("all");
  const [selectedId, setSelectedId] = useState(monsters[0]?.id ?? "");
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

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return monsters.filter((monster) =>
      (!needle || [monster.name, monster.territory, monster.terrain, monster.disposition, monster.rank, monster.gameplay_identity].join(" ").toLowerCase().includes(needle)) &&
      (cohort === "all" || monster.cohort === Number(cohort)) &&
      (territory === "all" || monster.territory === territory) &&
      (disposition === "all" || monster.disposition === disposition) &&
      (rank === "all" || monster.rank === rank) &&
      (artStatus === "all" || monster.art_status === artStatus) &&
      (reviewFilter === "all" || (reviews[monster.id]?.status ?? "unreviewed") === reviewFilter),
    );
  }, [monsters, query, cohort, territory, disposition, rank, artStatus, reviewFilter, reviews]);

  const selected = monsters.find((monster) => monster.id === selectedId) ?? filtered[0] ?? monsters[0];
  const generatedCount = monsters.filter((monster) => monster.art_status === "generated").length;
  const reviewedCount = Object.values(reviews).filter((review) => review.itemId.startsWith("monster_") && review.status !== "unreviewed").length;

  function getReview(monsterId: string): Review {
    return reviews[monsterId] ?? { itemId: monsterId, status: "unreviewed", notes: "", hidden: false };
  }

  function patchReview(patch: Partial<Review>) {
    if (!selected) return;
    setReviews((current) => ({ ...current, [selected.id]: { ...getReview(selected.id), ...patch } }));
    setSaveState("Unsaved changes");
  }

  async function saveReview() {
    if (!selected) return;
    const response = await fetch("/api/reviews", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(getReview(selected.id)),
    });
    if (!response.ok) {
      setSaveState("Could not save");
      return;
    }
    const payload = await response.json();
    setReviews((current) => ({ ...current, [selected.id]: payload.review }));
    setSaveState("Saved");
  }

  if (!selected) return null;
  const selectedReview = getReview(selected.id);

  return <main className="archive-shell monster-shell">
    <header className="masthead">
      <div className="brand-mark" aria-hidden="true">EA</div>
      <div className="brand-copy"><p className="eyebrow">The Enchanted Archive</p><h1>Creature Bestiary</h1><p>Benevolent neighbors, wary wildlife, hostile predators, and creatures waiting to be cleansed.</p></div>
      <nav className="archive-switch" aria-label="Archive section"><button onClick={onShowItems}>Equipment</button><button onClick={onShowTalents}>Talent trees</button><button className="active">Bestiary</button></nav>
      <div className="archive-tally"><strong>{monsters.length}</strong><span>drafted creatures</span></div>
    </header>

    <section className="tool-ribbon">
      <label className="search-box"><span>Search the bestiary</span><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Name, terrain, behavior…" /></label>
      <div className="summary-chip"><b>{generatedCount}</b> illustrated</div>
      <div className="summary-chip"><b>{reviewedCount}</b> reviewed</div>
      <div className={`storage-chip ${persistent ? "online" : "offline"}`}>{persistent ? "Curator ledger connected" : "Preview ledger unavailable"}</div>
    </section>

    <div className="archive-layout monster-layout">
      <aside className="filter-rail">
        <p className="section-kicker">Browse habitats</p>
        <FilterGroup title="Level cohort" value={cohort} onChange={setCohort} options={["all", ...new Set(monsters.map((monster) => String(monster.cohort)))]} labels={Object.fromEntries(monsters.map((monster) => [String(monster.cohort), `Levels ${monster.level_start}–${monster.level_end}`]))} />
        <FilterGroup title="Territory" value={territory} onChange={setTerritory} options={["all", ...new Set(monsters.map((monster) => monster.territory))]} />
        <FilterGroup title="Disposition" value={disposition} onChange={setDisposition} options={["all", ...new Set(monsters.map((monster) => monster.disposition))]} />
        <FilterGroup title="Rank" value={rank} onChange={setRank} options={["all", ...new Set(monsters.map((monster) => monster.rank))]} />
        <FilterGroup title="Artwork" value={artStatus} onChange={setArtStatus} options={["all", ...new Set(monsters.map((monster) => monster.art_status))]} />
        <FilterGroup title="Review" value={reviewFilter} onChange={setReviewFilter} options={["all", "unreviewed", "needs-work", "approved", "rejected"]} labels={statusLabels} />
        <div className="legend"><p className="section-kicker">Disposition rule</p><p>Benevolent and Neutral creatures are not ordinary farming targets. Hostile and Corrupted creatures support combat, cleansing, or rescue encounters.</p></div>
      </aside>

      <section className="item-library">
        <div className="library-heading"><div><p className="section-kicker">Creature records</p><h2>{filtered.length} creatures found</h2></div><span>Click a portrait to curate it</span></div>
        <div className="monster-grid">
          {filtered.map((monster) => {
            const review = getReview(monster.id);
            return <button className={`monster-card ${selected.id === monster.id ? "selected" : ""}`} key={monster.id} onClick={() => { setSelectedId(monster.id); setSaveState("Ready"); }}>
              <span className={`disposition-band ${monster.disposition.toLowerCase()}`} />
              {monster.image_path ? <img src={monster.image_path} alt="" width={160} height={160} /> : <span className="monster-placeholder" aria-hidden="true">{monster.name.split(" ").map((word) => word[0]).join("").slice(0, 2)}</span>}
              <span className="monster-card-copy"><small>Lv. {monster.level_start}–{monster.level_end} · {monster.rank}</small><strong>{monster.name}</strong><em>{monster.territory} · {monster.disposition}</em></span>
              <span className={`review-dot ${review.status}`} title={statusLabels[review.status]} />
            </button>;
          })}
        </div>
        {filtered.length === 0 && <div className="empty-state">No creature matches those filters.</div>}
      </section>

      <aside className="curator-panel monster-curator">
        <div className={`monster-hero ${selected.disposition.toLowerCase()}`}>{selected.image_path ? <img src={selected.image_path} alt={selected.name} width={280} height={280} /> : <span>{selected.name.split(" ").map((word) => word[0]).join("").slice(0, 2)}</span>}</div>
        <p className="item-id">{selected.id}</p><h2>{selected.name}</h2><p className="item-description">{selected.gameplay_identity}</p>
        <dl className="facts"><div><dt>Levels</dt><dd>{selected.level_start}–{selected.level_end}</dd></div><div><dt>Rank</dt><dd>{selected.rank}</dd></div><div><dt>Disposition</dt><dd>{selected.disposition}</dd></div><div><dt>Artwork</dt><dd>{humanize(selected.art_status)}</dd></div><div><dt>Territory</dt><dd>{selected.territory}</dd></div><div><dt>Terrain</dt><dd>{selected.terrain}</dd></div></dl>
        <div className="curator-form"><p className="section-kicker">Curator ledger</p><label>Status<select value={selectedReview.status} onChange={(event) => patchReview({ status: event.target.value })}>{Object.entries(statusLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label><label>Notes<textarea value={selectedReview.notes} onChange={(event) => patchReview({ notes: event.target.value })} placeholder="Name, silhouette, disposition, encounter behavior, or replacement idea…" /></label><label className="check-row"><input type="checkbox" checked={selectedReview.hidden} onChange={(event) => patchReview({ hidden: event.target.checked })} />Hidden or secret creature</label><button className="save-button" onClick={() => { setSaveState("Saving…"); void saveReview(); }}>Save to curator ledger</button><span className="save-state">{saveState}</span></div>
      </aside>
    </div>
  </main>;
}

function FilterGroup({ title, value, onChange, options, labels = {} }: { title: string; value: string; onChange: (value: string) => void; options: string[]; labels?: Record<string, string> }) {
  return <fieldset className="filter-group"><legend>{title}</legend>{options.map((option) => <button className={value === option ? "active" : ""} onClick={() => onChange(option)} key={option}>{labels[option] ?? humanize(option)}</button>)}</fieldset>;
}
