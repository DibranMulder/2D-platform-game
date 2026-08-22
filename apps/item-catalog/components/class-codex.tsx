"use client";

import { useEffect, useMemo, useState } from "react";

export type Talent = { id: string; name: string; level: number; description: string };
export type TalentBranch = { id: string; name: string; talents: Talent[] };
export type CombatClass = {
  id: string;
  name: string;
  promise: string;
  weapons: string[];
  armor: string;
  signatureStat: string;
  branches: TalentBranch[];
};

type Review = { itemId: string; status: string; notes: string; hidden: boolean; updatedAt?: string };

const statusLabels: Record<string, string> = {
  unreviewed: "Unreviewed",
  "needs-work": "Needs work",
  approved: "Approved",
  rejected: "Rejected",
};

export function ClassCodex({ classes, onShowItems, onShowMonsters }: { classes: CombatClass[]; onShowItems: () => void; onShowMonsters: () => void }) {
  const [selectedClassId, setSelectedClassId] = useState(classes[0]?.id ?? "");
  const [selectedTalentId, setSelectedTalentId] = useState(classes[0]?.branches[0]?.talents[0]?.id ?? "");
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

  const selectedClass = classes.find((entry) => entry.id === selectedClassId) ?? classes[0];
  const classTalents = useMemo(() => selectedClass?.branches.flatMap((branch) => branch.talents) ?? [], [selectedClass]);
  const selectedTalent = classTalents.find((talent) => talent.id === selectedTalentId) ?? classTalents[0];
  const selectedBranch = selectedClass?.branches.find((branch) => branch.talents.some((talent) => talent.id === selectedTalent?.id));
  const talentCount = classes.flatMap((entry) => entry.branches.flatMap((branch) => branch.talents)).length;
  const reviewedTalents = Object.values(reviews).filter((review) => review.itemId.startsWith("talent_") && review.status !== "unreviewed").length;

  function selectClass(classId: string) {
    const next = classes.find((entry) => entry.id === classId);
    setSelectedClassId(classId);
    setSelectedTalentId(next?.branches[0]?.talents[0]?.id ?? "");
    setSaveState("Ready");
  }

  function getReview(talentId: string): Review {
    return reviews[talentId] ?? { itemId: talentId, status: "unreviewed", notes: "", hidden: false };
  }

  function patchReview(patch: Partial<Review>) {
    if (!selectedTalent) return;
    setReviews((current) => ({ ...current, [selectedTalent.id]: { ...getReview(selectedTalent.id), ...patch } }));
    setSaveState("Unsaved changes");
  }

  async function saveReview() {
    if (!selectedTalent) return;
    const review = getReview(selectedTalent.id);
    setSaveState("Saving…");
    const response = await fetch("/api/reviews", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(review),
    });
    if (!response.ok) {
      setSaveState("Could not save");
      return;
    }
    const payload = await response.json();
    setReviews((current) => ({ ...current, [selectedTalent.id]: payload.review }));
    setSaveState("Saved");
  }

  if (!selectedClass || !selectedTalent) return null;
  const selectedReview = getReview(selectedTalent.id);

  return (
    <main className="archive-shell talent-shell">
      <header className="masthead">
        <div className="brand-mark" aria-hidden="true">EA</div>
        <div className="brand-copy"><p className="eyebrow">The Enchanted Archive</p><h1>Class Codex</h1><p>Six paths, eighteen talents each, and one hundred twenty levels of specialization.</p></div>
        <nav className="archive-switch" aria-label="Archive section"><button onClick={onShowItems}>Equipment</button><button className="active">Talent trees</button><button onClick={onShowMonsters}>Bestiary</button></nav>
        <div className="archive-tally"><strong>{talentCount}</strong><span>class talents</span></div>
      </header>

      <section className="tool-ribbon talent-ribbon">
        <div><p className="section-kicker">{selectedClass.name}</p><strong>{selectedClass.promise}</strong></div>
        <div className="summary-chip"><b>{reviewedTalents}</b> reviewed</div>
        <div className={`storage-chip ${persistent ? "online" : "offline"}`}>{persistent ? "Curator ledger connected" : "Preview ledger unavailable"}</div>
      </section>

      <div className="talent-layout">
        <aside className="class-rail">
          <p className="section-kicker">Combat classes</p>
          {classes.map((entry) => <button className={entry.id === selectedClass.id ? "active" : ""} key={entry.id} onClick={() => selectClass(entry.id)}><strong>{entry.name}</strong><span>{entry.branches.map((branch) => branch.name).join(" · ")}</span></button>)}
          <div className="class-profile"><p className="section-kicker">Equipment identity</p><p><b>Weapons</b>{selectedClass.weapons.join(", ")}</p><p><b>Armor</b>{selectedClass.armor}</p><p><b>Signature stat</b>{selectedClass.signatureStat}</p></div>
        </aside>

        <section className="talent-library">
          <div className="library-heading"><div><p className="section-kicker">Distinct specializations</p><h2>{selectedClass.name}</h2></div><span>12 points available by level 120 · choose up to two complete branches</span></div>
          <div className="talent-branches">
            {selectedClass.branches.map((branch) => <section className="talent-branch" key={branch.id}>
              <header><span>{branch.name.slice(0, 2).toUpperCase()}</span><h3>{branch.name}</h3></header>
              {branch.talents.map((talent, index) => {
                const review = getReview(talent.id);
                return <button className={`talent-node ${talent.id === selectedTalent.id ? "selected" : ""}`} key={talent.id} onClick={() => { setSelectedTalentId(talent.id); setSaveState("Ready"); }}>
                  <span className="talent-level">Lv. {talent.level}</span><span className="talent-copy"><strong>{talent.name}</strong><small>{talent.description}</small></span><span className={`review-dot ${review.status}`} title={statusLabels[review.status]} />{index < branch.talents.length - 1 && <i aria-hidden="true" />}
                </button>;
              })}
            </section>)}
          </div>
        </section>

        <aside className="curator-panel talent-curator">
          <div className="talent-seal" aria-hidden="true">{selectedBranch?.name.slice(0, 2).toUpperCase()}</div>
          <p className="item-id">{selectedTalent.id}</p><h2>{selectedTalent.name}</h2><p className="item-description">{selectedTalent.description}</p>
          <dl className="facts"><div><dt>Class</dt><dd>{selectedClass.name}</dd></div><div><dt>Branch</dt><dd>{selectedBranch?.name}</dd></div><div><dt>Unlock</dt><dd>Level {selectedTalent.level}</dd></div><div><dt>Cost</dt><dd>1 point</dd></div></dl>
          <div className="curator-form"><p className="section-kicker">Curator ledger</p><label>Status<select value={selectedReview.status} onChange={(event) => patchReview({ status: event.target.value })}>{Object.entries(statusLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label><label>Notes<textarea value={selectedReview.notes} onChange={(event) => patchReview({ notes: event.target.value })} placeholder="Name, role, balance, fantasy, or replacement idea…" /></label><label className="check-row"><input type="checkbox" checked={selectedReview.hidden} onChange={(event) => patchReview({ hidden: event.target.checked })} />Hide this talent from the working tree</label><button className="save-button" onClick={saveReview}>Save to curator ledger</button><span className="save-state">{saveState}</span></div>
        </aside>
      </div>
    </main>
  );
}
