import { type Locale, fallbackLng } from "../i18n/settings";
import { Button } from "@/components/ui/button";
import { GooglePlayIcon, AppStoreIcon } from "@/components/ui/icons";
import { getDictionary } from "../dictionaries/get-dictonaries";

export default async function ComingSoonPage({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dict = await getDictionary(lang || fallbackLng);

  return (
    <div className="container mx-auto px-4 py-8 text-center">
      <h1 className="text-4xl font-bold mb-8">{dict.comingSoon}</h1>

      <div className="flex justify-center space-x-4 mb-8">
        <Button className="flex items-center">
          <GooglePlayIcon className="mr-2" />
          {dict.downloadGooglePlay}
        </Button>
        <Button className="flex items-center">
          <AppStoreIcon className="mr-2" />
          {dict.downloadAppStore}
        </Button>
      </div>

      <Button variant="outline" className="mb-12">
        {dict.termsAndConditions}
      </Button>

      <section className="max-w-2xl mx-auto">
        <h2 className="text-2xl font-semibold mb-4">{dict.contactUs}</h2>
        <p>{dict.contactUsDescription}</p>
      </section>
    </div>
  );
}
