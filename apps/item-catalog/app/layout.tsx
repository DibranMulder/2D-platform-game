import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Item Chronicle · The Enchanted Archive",
  description: "Curate the equipment, treasures, materials, and hidden finds of the Enchanted Archive.",
  openGraph: {
    title: "Item Chronicle · The Enchanted Archive",
    description: "A living catalogue of every blade, boot, bauble, and secret worth finding.",
    images: ["/og.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return <html lang="en"><body>{children}</body></html>;
}
