import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "@/app/globals.css";
import { fallbackLng } from "@/app/i18n/settings";

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
