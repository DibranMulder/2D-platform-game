import { readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, "../../..");
const designDirectory = resolve(repositoryRoot, "docs/design");
const gameCatalogPath = resolve(repositoryRoot, "client/data/items.json");
const siteCatalogPath = resolve(repositoryRoot, "apps/item-catalog/content/items.json");
const classCatalogPath = resolve(repositoryRoot, "apps/item-catalog/content/classes.json");
const monsterCatalogPath = resolve(repositoryRoot, "apps/item-catalog/content/monsters.json");
const designOrigin = "design-0012";

const classOrder = ["Vanguard", "Ravager", "Ranger", "Duelist", "Arcanist", "Warden"];
const classMetadata = {
  Vanguard: {
    promise: "Guard, counters, formation play, and dependable melee.",
    weapons: ["One-Handed Sword", "One-Handed Axe", "One-Handed Blunt", "Spear", "Shield"],
    armor: "Heavy plate with broad shoulders and a readable shield silhouette.",
    signatureStat: "guard",
  },
  Ravager: {
    promise: "Committed heavy swings, stagger, armor breaking, and controlled risk.",
    weapons: ["Two-Handed Sword", "Two-Handed Axe", "Two-Handed Blunt", "Polearm"],
    armor: "Heavy or reinforced medium armor with a weight-forward silhouette.",
    signatureStat: "power",
  },
  Ranger: {
    promise: "Ranged pressure, weak-point shots, traps, and mobile fieldcraft.",
    weapons: ["Bow", "Crossbow", "Spear"],
    armor: "Medium leather and light mail with compact, practical shapes.",
    signatureStat: "agility",
  },
  Duelist: {
    promise: "Two one-handed weapons, evasive footwork, bleeds, and precise counters.",
    weapons: ["One-Handed Sword", "One-Handed Axe", "Dagger"],
    armor: "Light leather and cloth with deliberate asymmetry.",
    signatureStat: "agility",
  },
  Arcanist: {
    promise: "Elemental projectiles, zones, control, and fragile magical burst.",
    weapons: ["Wand", "Staff"],
    armor: "Layered elemental robes with large readable sleeves.",
    signatureStat: "arcana",
  },
  Warden: {
    promise: "Radiance protection, Gloam curses, life transfer, or an Eclipse balance.",
    weapons: ["Wand", "Staff"],
    armor: "Asymmetric polarity robes with paired luminous and umbral details.",
    signatureStat: "focus",
  },
};

const armorPieces = {
  Vanguard: { head: "Helm", shoulders: "Pauldrons", chest: "Cuirass", hands: "Gauntlets", legs: "Greaves", feet: "Sabatons" },
  Ravager: { head: "Warhelm", shoulders: "Spaulders", chest: "Harness", hands: "Grips", legs: "Chausses", feet: "Warboots" },
  Ranger: { head: "Hood", shoulders: "Shoulderguard", chest: "Jerkin", hands: "Bracers", legs: "Trousers", feet: "Trailboots" },
  Duelist: { head: "Mask", shoulders: "Shoulder Sash", chest: "Doublet", hands: "Gloves", legs: "Breeches", feet: "Softboots" },
  Arcanist: { head: "Circlet", shoulders: "Epaulets", chest: "Robe", hands: "Gloves", legs: "Legwraps", feet: "Slippers" },
  Warden: { head: "Diadem", shoulders: "Polarity Mantle", chest: "Vestment", hands: "Handwraps", legs: "Legwraps", feet: "Boots" },
};

const armorIcon = { head: 10, shoulders: 11, chest: 7, hands: 9, legs: 6, feet: 8 };
const armorSlotWeight = { head: 1, shoulders: 1, chest: 3, hands: 1, legs: 2, feet: 1 };
const generatedArmorIcons = {
  "Vanguard|1|Roadwarden|head": "/items/generated/tier-01/vanguard/roadwarden-head.png",
  "Vanguard|1|Roadwarden|shoulders": "/items/generated/tier-01/vanguard/roadwarden-shoulders.png",
  "Vanguard|1|Roadwarden|chest": "/items/generated/tier-01/vanguard/roadwarden-chest.png",
  "Vanguard|1|Roadwarden|hands": "/items/generated/tier-01/vanguard/roadwarden-hands.png",
  "Vanguard|1|Roadwarden|legs": "/items/generated/tier-01/vanguard/roadwarden-legs.png",
  "Vanguard|1|Roadwarden|feet": "/items/generated/tier-01/vanguard/roadwarden-feet.png",
};

const weaponDefinitions = {
  "1H Sword": { id: "single_handed_sword", label: "One-Handed Sword", classes: ["Vanguard", "Duelist"], grip: "one_hand", icon: 0 },
  "2H Sword": { id: "two_handed_sword", label: "Two-Handed Sword", classes: ["Ravager"], grip: "two_hand", icon: 1 },
  "1H Axe": { id: "single_handed_axe", label: "One-Handed Axe", classes: ["Vanguard", "Duelist"], grip: "one_hand", icon: 17 },
  "2H Axe": { id: "two_handed_axe", label: "Two-Handed Axe", classes: ["Ravager"], grip: "two_hand", icon: 17 },
  Spear: { id: "spear", label: "Spear", classes: ["Vanguard", "Ranger"], grip: "two_hand", icon: 3 },
  Polearm: { id: "polearm", label: "Polearm", classes: ["Ravager"], grip: "two_hand", icon: 3 },
  Crossbow: { id: "crossbow", label: "Crossbow", classes: ["Ranger"], grip: "two_hand", icon: 2 },
  Bow: { id: "bow", label: "Bow", classes: ["Ranger"], grip: "two_hand", icon: 2 },
  Wand: { id: "wand", label: "Wand", classes: ["Arcanist", "Warden"], grip: "one_hand", icon: 3 },
  Staff: { id: "staff", label: "Staff", classes: ["Arcanist", "Warden"], grip: "two_hand", icon: 3 },
  Shield: { id: "shield", label: "Shield", classes: ["Vanguard"], grip: "one_hand", icon: 4 },
  Dagger: { id: "dagger", label: "Dagger", classes: ["Duelist"], grip: "one_hand", icon: 0 },
  "1H Blunt": { id: "single_handed_blunt", label: "One-Handed Blunt", classes: ["Vanguard"], grip: "one_hand", icon: 5 },
  "2H Blunt": { id: "two_handed_blunt", label: "Two-Handed Blunt", classes: ["Ravager"], grip: "two_hand", icon: 5 },
};
const generatedWeaponIcons = {
  "single_handed_sword|1|Roadworn Blade": "/items/generated/tier-01/weapons/roadworn-blade.png",
  "two_handed_sword|1|Old Iron Greatblade": "/items/generated/tier-01/weapons/old-iron-greatblade.png",
  "shield|1|Driftwood Buckler": "/items/generated/tier-01/weapons/driftwood-buckler.png",
};

function slug(value) {
  return value
    .toLowerCase()
    .replace(/[’']/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function iconPath(index) {
  return `/items/icon-${String(index).padStart(2, "0")}.png`;
}

function parseTableAfter(markdown, heading) {
  const start = markdown.indexOf(heading);
  if (start < 0) throw new Error(`Missing design heading: ${heading}`);
  const lines = markdown.slice(start + heading.length).split("\n");
  const firstRow = lines.findIndex((line) => line.trim().startsWith("|"));
  if (firstRow < 0) throw new Error(`Missing table after: ${heading}`);
  const rows = [];
  for (const line of lines.slice(firstRow)) {
    if (!line.trim().startsWith("|")) break;
    rows.push(line.split("|").slice(1, -1).map((cell) => cell.trim()));
  }
  const headers = rows[0];
  return rows.slice(2).map((cells) => Object.fromEntries(headers.map((header, index) => [header, cells[index]])));
}

function qualityFor(tier, refined) {
  const rank = tier <= 4 ? 0 : tier <= 8 ? 1 : tier <= 11 ? 2 : 3;
  return ["common", "uncommon", "rare", "epic"][Math.min(3, rank + (refined ? 1 : 0))];
}

function levelFor(tier, refined) {
  return (tier - 1) * 10 + (refined ? 6 : 1);
}

function buildArmorItems(armorRows) {
  const items = [];
  for (const row of armorRows) {
    const tier = Number(row.Tier);
    for (const className of classOrder) {
      const setFamily = row[className];
      for (const [slot, suffix] of Object.entries(armorPieces[className])) {
        const generatedIcon = generatedArmorIcons[`${className}|${tier}|${setFamily}|${slot}`];
        for (const form of ["base", "refined"]) {
          const refined = form === "refined";
          const level = levelFor(tier, refined);
          const defense = tier * 3 + armorSlotWeight[slot] + (refined ? 2 : 0);
          const signatureStat = classMetadata[className].signatureStat;
          const name = `${refined ? "Refined " : ""}${setFamily} ${suffix}`;
          items.push({
            id: `armor_${slug(className)}_t${String(tier).padStart(2, "0")}_${slug(setFamily)}_${slot}_${form}`,
            name,
            category: "armor",
            slot,
            weapon_family: "",
            grip: "",
            offhand_compatible: false,
            quality: qualityFor(tier, refined),
            level,
            tier,
            form,
            set_family: setFamily,
            combat_classes: [className],
            price: level * 24 + armorSlotWeight[slot] * 18,
            icon: suffix.slice(0, 2).toUpperCase(),
            icon_path: generatedIcon ?? iconPath(armorIcon[slot]),
            description: `${form === "refined" ? "The polished midpoint form of" : "The base form of"} the Tier ${tier} ${className} ${setFamily} set. Its acquisition method has not been assigned.`,
            stats: { defense, [signatureStat]: Math.max(1, Math.ceil(tier / 2) + (refined ? 1 : 0)) },
            body_families: ["all_playable_lineages"],
            source: "Acquisition not assigned",
            tags: [slug(className), `tier-${tier}`, form, slug(setFamily), "class-armor", generatedIcon ? (refined ? "base-art-reuse" : "generated-icon") : "placeholder-icon"],
            art_status: generatedIcon ? (refined ? "refined-variant-needed" : "generated") : "concept-needed",
            sprite_status: "lineage-variants-needed",
            design_origin: designOrigin,
          });
        }
      }
    }
  }
  return items;
}

function buildWeaponItems(weaponRows) {
  const items = [];
  for (const row of weaponRows) {
    const tier = Number(row.Tier);
    for (const [column, baseName] of Object.entries(row)) {
      if (column === "Tier") continue;
      const definition = weaponDefinitions[column];
      if (!definition) throw new Error(`No weapon definition for ${column}`);
      const generatedIcon = generatedWeaponIcons[`${definition.id}|${tier}|${baseName}`];
      for (const form of ["base", "refined"]) {
        const refined = form === "refined";
        const level = levelFor(tier, refined);
        const isShield = definition.id === "shield";
        const isMagic = definition.id === "wand" || definition.id === "staff";
        const name = `${refined ? "Refined " : ""}${baseName}`;
        const stats = isShield
          ? { defense: tier * 3 + (refined ? 2 : 0), guard: tier * 4 + (refined ? 2 : 0) }
          : isMagic
            ? { arcana: tier * 4 + (refined ? 2 : 0), focus: tier * 2 + (refined ? 1 : 0) }
            : { attack: tier * 4 + (refined ? 2 : 0), power: tier * 2 + (refined ? 1 : 0) };
        items.push({
          id: `${isShield ? "shield" : "weapon"}_${definition.id}_t${String(tier).padStart(2, "0")}_${slug(baseName)}_${form}`,
          name,
          category: isShield ? "shield" : "weapon",
          slot: isShield ? "off_hand" : "main_hand",
          allowed_slots: definition.grip === "one_hand" && !isShield ? ["main_hand", "off_hand"] : [isShield ? "off_hand" : "main_hand"],
          weapon_family: definition.id,
          grip: definition.grip,
          offhand_compatible: definition.grip === "one_hand" && !isShield,
          quality: qualityFor(tier, refined),
          level,
          tier,
          form,
          set_family: baseName,
          combat_classes: definition.classes,
          price: level * 30 + (definition.grip === "two_hand" ? 45 : 20),
          icon: definition.label.split(" ").map((word) => word[0]).join("").slice(0, 2).toUpperCase(),
          icon_path: generatedIcon ?? iconPath(definition.icon),
          description: `${form === "refined" ? "The refined midpoint form" : "The base form"} of this Tier ${tier} ${definition.label}. Its acquisition method has not been assigned.`,
          stats,
          body_families: ["all_playable_lineages"],
          source: "Acquisition not assigned",
          tags: [...definition.classes.map(slug), `tier-${tier}`, form, definition.id, "class-weapon", generatedIcon ? (refined ? "base-art-reuse" : "generated-icon") : "placeholder-icon"],
          art_status: generatedIcon ? (refined ? "refined-variant-needed" : "generated") : "concept-needed",
          sprite_status: "lineage-variants-needed",
          design_origin: designOrigin,
        });
      }
    }
  }
  return items;
}

function buildClassCatalog(talentMarkdown) {
  const classes = classOrder.map((className) => {
    const sectionStart = talentMarkdown.indexOf(`## ${className}`);
    if (sectionStart < 0) throw new Error(`Missing talent section for ${className}`);
    const nextSection = talentMarkdown.indexOf("\n## ", sectionStart + 3);
    const section = talentMarkdown.slice(sectionStart, nextSection < 0 ? undefined : nextSection);
    const rows = parseTableAfter(section, `## ${className}`);
    const levelColumns = Object.keys(rows[0]).slice(1);
    const branches = rows.map((row) => ({
      id: slug(row.Branch),
      name: row.Branch,
      talents: levelColumns.map((column) => {
        const match = row[column].match(/^\*\*(.+?)\*\*\s+—\s+(.+)$/);
        if (!match) throw new Error(`Could not parse ${className} ${row.Branch} ${column}`);
        const level = Number(column.replace("Level ", ""));
        return {
          id: `talent_${slug(className)}_${slug(row.Branch)}_${slug(match[1])}`,
          name: match[1],
          level,
          description: match[2],
        };
      }),
    }));
    return {
      id: slug(className),
      name: className,
      ...classMetadata[className],
      branches,
    };
  });
  return { schema_version: 1, design_origin: "design-0013", classes };
}

function buildMonsterCatalog(creatureMarkdown) {
  const territories = ["Open Lands", "Tidekin Sea", "Elder Forest", "Sky Reaches", "Broken Mountains", "Underdeep", "Ember Desert", "Ice Lands"];
  const headings = [...creatureMarkdown.matchAll(/^### Levels (\d+)–(\d+)$/gm)];
  const monsters = [];
  for (let index = 0; index < headings.length; index += 1) {
    const heading = headings[index];
    const levelStart = Number(heading[1]);
    const levelEnd = Number(heading[2]);
    const sectionEnd = headings[index + 1]?.index ?? creatureMarkdown.length;
    const section = creatureMarkdown.slice(heading.index, sectionEnd);
    const rows = parseTableAfter(section, heading[0]);
    for (const row of rows) {
      const territory = territories.find((candidate) => row["Territory and terrain"].startsWith(candidate));
      if (!territory) throw new Error(`Unknown monster territory: ${row["Territory and terrain"]}`);
      const terrain = row["Territory and terrain"].slice(territory.length).trim();
      const [disposition, rank] = row["Disposition / rank"].split(" / ");
      const id = `monster_${slug(row.Creature)}`;
      const hasArtwork = levelEnd <= 10;
      monsters.push({
        id,
        name: row.Creature,
        level_start: levelStart,
        level_end: levelEnd,
        cohort: Math.ceil(levelEnd / 5),
        territory,
        terrain,
        disposition,
        rank,
        gameplay_identity: row["Gameplay identity"],
        art_status: hasArtwork ? "generated" : "concept-needed",
        image_path: hasArtwork ? `/monsters/levels-${String(levelStart).padStart(2, "0")}-${String(levelEnd).padStart(2, "0")}/${slug(row.Creature).replaceAll("_", "-")}.png` : "",
        source_doc: "DESIGN-0011",
      });
    }
  }
  return { schema_version: 1, generated_from: "DESIGN-0011", monsters };
}

const equipmentMarkdown = await readFile(resolve(designDirectory, "0012-combat-classes-and-equipment-tiers.md"), "utf8");
const talentMarkdown = await readFile(resolve(designDirectory, "0013-class-talent-trees.md"), "utf8");
const creatureMarkdown = await readFile(resolve(designDirectory, "0011-creature-roster.md"), "utf8");
const existingCatalog = JSON.parse(await readFile(gameCatalogPath, "utf8"));
const preservedItems = existingCatalog.items.filter((item) => item.design_origin !== designOrigin);

const armorRows = parseTableAfter(equipmentMarkdown, "## Armor family matrix");
const reachWeaponRows = parseTableAfter(equipmentMarkdown, "### Blades, axes, and reach weapons");
const otherWeaponRows = parseTableAfter(equipmentMarkdown, "### Ranged, arcane, defensive, and close weapons");
const generatedItems = [...buildArmorItems(armorRows), ...buildWeaponItems([...reachWeaponRows, ...otherWeaponRows])];
const itemCatalog = { schema_version: 2, generated_from: "DESIGN-0012", items: [...preservedItems, ...generatedItems] };
const classCatalog = buildClassCatalog(talentMarkdown);
const monsterCatalog = buildMonsterCatalog(creatureMarkdown);

if (generatedItems.length !== 1200) throw new Error(`Expected 1200 generated items, received ${generatedItems.length}`);
if (classCatalog.classes.flatMap((entry) => entry.branches.flatMap((branch) => branch.talents)).length !== 108) {
  throw new Error("Expected 108 generated talents");
}
if (new Set(itemCatalog.items.map((item) => item.id)).size !== itemCatalog.items.length) throw new Error("Duplicate item IDs generated");

const serializedItems = `${JSON.stringify(itemCatalog, null, 2)}\n`;
await Promise.all([
  writeFile(gameCatalogPath, serializedItems),
  writeFile(siteCatalogPath, serializedItems),
  writeFile(classCatalogPath, `${JSON.stringify(classCatalog, null, 2)}\n`),
  writeFile(monsterCatalogPath, `${JSON.stringify(monsterCatalog, null, 2)}\n`),
]);

console.log(`Wrote ${itemCatalog.items.length} catalogue items (${generatedItems.length} generated, ${preservedItems.length} preserved).`);
console.log(`Wrote ${classCatalog.classes.length} classes and 108 talents.`);
console.log(`Wrote ${monsterCatalog.monsters.length} drafted monsters (${monsterCatalog.monsters.filter((monster) => monster.art_status === "generated").length} with artwork).`);
