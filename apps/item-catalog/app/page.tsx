import itemData from "../content/items.json";
import classData from "../content/classes.json";
import monsterData from "../content/monsters.json";
import { ItemArchive, type Item } from "../components/item-archive";
import type { CombatClass } from "../components/class-codex";
import type { Monster } from "../components/monster-bestiary";

export default function Home() {
  return <ItemArchive items={itemData.items as Item[]} classes={classData.classes as CombatClass[]} monsters={monsterData.monsters as Monster[]} />;
}
