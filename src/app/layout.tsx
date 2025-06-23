import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Ta'aafi Platform Admin Portal",
  description: "Ta'aafi Platform Admin Portal",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar">
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
