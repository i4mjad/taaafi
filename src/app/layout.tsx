import type { Metadata, Viewport } from "next";
import "@/app/globals.css";

export const viewport: Viewport = {
  themeColor: '#FFFFFF',
};

export const metadata: Metadata = {
  title: "Ta'aafi App",
  description: "Ta'aafi App Website",
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon.svg', type: 'image/svg+xml' }
    ],
    apple: '/apple-touch-icon.png',
  },
  manifest: '/site.webmanifest',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children; // Remove html and body tags from root layout
}
