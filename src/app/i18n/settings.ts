export const fallbackLng = "en";
export const languages = [fallbackLng, "ar"] as const;

export type Locale = (typeof languages)[number];

export const defaultNS = "translation";

export function getOptions(lng: Locale = fallbackLng, ns = defaultNS) {
  return {
    supportedLngs: languages,
    fallbackLng,
    lng,
    fallbackNS: defaultNS,
    defaultNS,
    ns,
  };
}
