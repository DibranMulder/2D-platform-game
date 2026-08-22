import { NextResponse } from "next/server";
import { eq } from "drizzle-orm";
import { getDb } from "../../../db";
import { itemReviews } from "../../../db/schema";

const statuses = new Set(["unreviewed", "needs-work", "approved", "rejected"]);

export async function GET() {
  try {
    const reviews = await getDb().select().from(itemReviews);
    return NextResponse.json({ reviews, persistent: true });
  } catch (error) {
    console.error("Could not load curator reviews", error);
    return NextResponse.json({ reviews: [], persistent: false });
  }
}

export async function PUT(request: Request) {
  const body = (await request.json()) as {
    itemId?: string;
    status?: string;
    notes?: string;
    hidden?: boolean;
  };
  if (!body.itemId || !body.status || !statuses.has(body.status)) {
    return NextResponse.json({ error: "Invalid review" }, { status: 400 });
  }

  const review = {
    itemId: body.itemId,
    status: body.status,
    notes: String(body.notes ?? "").slice(0, 4000),
    hidden: Boolean(body.hidden),
    updatedAt: new Date().toISOString(),
  };

  try {
    const db = getDb();
    await db
      .insert(itemReviews)
      .values(review)
      .onConflictDoUpdate({
        target: itemReviews.itemId,
        set: {
          status: review.status,
          notes: review.notes,
          hidden: review.hidden,
          updatedAt: review.updatedAt,
        },
      });
    const [saved] = await db
      .select()
      .from(itemReviews)
      .where(eq(itemReviews.itemId, review.itemId));
    return NextResponse.json({ review: saved });
  } catch (error) {
    console.error("Could not save curator review", error);
    return NextResponse.json({ error: "Review storage unavailable" }, { status: 503 });
  }
}
