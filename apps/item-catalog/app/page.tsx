import itemData from "../content/items.json";
import { ItemArchive, type Item } from "../components/item-archive";

export default function Home() {
  return <ItemArchive items={itemData.items as Item[]} />;
}
