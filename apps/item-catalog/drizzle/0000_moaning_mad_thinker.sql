CREATE TABLE `item_reviews` (
	`item_id` text PRIMARY KEY NOT NULL,
	`status` text DEFAULT 'unreviewed' NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`hidden` integer DEFAULT false NOT NULL,
	`updated_at` text NOT NULL
);
