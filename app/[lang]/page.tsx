import { type Locale, fallbackLng } from "../i18n/settings";
import { getDictionary } from "../dictionaries/get-dictonaries";
import { Button } from "../../components/ui/button";
import { AppStoreIcon, GooglePlayIcon } from "../../components/ui/icons";

export default async function ComingSoonPage({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dict = await getDictionary(lang || fallbackLng);

  return (
    <div className="min-h-screen flex items-center">
      <div className="container mx-auto px-4 py-8 text-center">
        <div className="max-w-2xl mx-auto">
          <h1 className="text-4xl font-bold mb-8">{dict.comingSoon}</h1>
          <h2
            className="text-2xl font-semibold mb-4"
            style={{ color: "#ff5733" }}
          >
            {dict.latestVersionAvailable}
          </h2>
          <div className="flex flex-col justify-center gap-2 mb-8 mx-auto">
            <Button asChild className="flex items-center justify-center">
              <a
                href="https://play.google.com/store/apps/details?id=com.ta3afi.app"
                target="_blank"
                rel="noopener noreferrer"
              >
                <GooglePlayIcon className="mr-2" />
                {dict.downloadGooglePlay}
              </a>
            </Button>
            <Button asChild className="flex items-center justify-center">
              <a
                href="https://apps.apple.com/om/app/reboot-app-for-better-life/id1531562469"
                target="_blank"
                rel="noopener noreferrer"
              >
                <AppStoreIcon className="mr-2" />
                {dict.downloadAppStore}
              </a>
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
      </div>
    </div>
  );
}
