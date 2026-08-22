// Intentionally empty by default.
// Add Drizzle tables here when the site actually needs a database.
// See examples/d1/db/schema.ts for an opt-in example.
export {};
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

export const itemReviews = sqliteTable("item_reviews", {
  itemId: text("item_id").primaryKey(),
  status: text("status").notNull().default("unreviewed"),
  notes: text("notes").notNull().default(""),
  hidden: integer("hidden", { mode: "boolean" }).notNull().default(false),
  updatedAt: text("updated_at").notNull(),
});
