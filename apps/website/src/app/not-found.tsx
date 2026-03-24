import Link from "next/link";

export default function NotFound() {
  return (
    <html lang="ar" dir="rtl">
      <body className="flex min-h-screen flex-col font-expo-arabic">
        <div className="flex flex-1 flex-col items-center justify-center px-4 text-center">
          <h1 className="text-6xl font-bold mb-4">404</h1>
          <p className="text-xl text-gray-600 mb-8">
            الصفحة غير موجودة
          </p>
          <Link
            href="/ar"
            className="rounded-lg bg-black px-6 py-3 text-white hover:bg-gray-800 transition-colors"
          >
            العودة للرئيسية
          </Link>
        </div>
      </body>
    </html>
  );
}
