import type { Metadata } from "next";
import "@/app/globals.css";

export const metadata: Metadata = {
  title: "Ta'aafi App",
  description: "Ta'aafi App Website",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children; // Remove html and body tags from root layout
}
