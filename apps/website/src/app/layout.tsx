import type { Metadata, Viewport } from "next";
import "@/app/globals.css";

const BASE_URL = "https://ta3afi.app";

export const viewport: Viewport = {
  themeColor: '#FFFFFF',
};

export const metadata: Metadata = {
  metadataBase: new URL(BASE_URL),
  title: {
    default: "Ta'aafi - Break Free from Addiction | منصة تعافي",
    template: "%s | Ta'aafi",
  },
  description:
    "Ta'aafi is a comprehensive recovery platform helping thousands overcome porn addiction and build healthier habits. Available on iOS and Android.",
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon.svg', type: 'image/svg+xml' }
    ],
    apple: '/apple-touch-icon.png',
  },
  manifest: '/site.webmanifest',
  openGraph: {
    type: "website",
    siteName: "Ta'aafi",
    locale: "ar_SA",
    alternateLocale: "en_US",
    images: [
      {
        url: "/app-icon.png",
        width: 512,
        height: 512,
        alt: "Ta'aafi App Icon",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    site: "@ta3afi",
    creator: "@ta3afi",
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children; // Remove html and body tags from root layout
}
