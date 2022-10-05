import { createI18n } from "vue-i18n";
import en from "../i18n/en_US.json";
import langs from "../i18n/langs.json";
import { getLocaleData } from "./auth";
import pluralizationRules from "../i18n/pluralRules";

const DEFAULT_LOCALE = "en_US";

const localeInLocalStorage = getLocaleData();

export const AVAILABLE_LANGUAGES = Object.keys(langs);

let language =
  localeInLocalStorage ||
  (document.documentElement.getAttribute("lang") as string);

language =
  language ||
  ((window.navigator as any).userLanguage || window.navigator.language).replace(
    /-/,
    "_"
  );

export const locale =
  language && Object.prototype.hasOwnProperty.call(langs, language)
    ? language
    : language.split("-")[0];

export const i18n = createI18n({
  legacy: false,
  locale: locale, // set locale
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  // messages, // set locale messages
  messages: en, // set locale messages
  fallbackLocale: DEFAULT_LOCALE,
  formatFallbackMessages: true,
  pluralizationRules,
  fallbackRootWithEmptyString: true,
  globalInjection: true,
});

const loadedLanguages = [DEFAULT_LOCALE];

function setI18nLanguage(lang: string): string {
  i18n.global.locale = lang;
  setLanguageInDOM(lang);
  return lang;
}

function setLanguageInDOM(lang: string): void {
  const fixedLang = lang.replace(/_/g, "-");
  const html = document.documentElement;
  const documentLang = html.getAttribute("lang");
  if (documentLang !== fixedLang) {
    html.setAttribute("lang", fixedLang);
  }

  const direction = ["ar", "ae", "he", "fa", "ku", "ur"].includes(fixedLang)
    ? "rtl"
    : "ltr";
  html.setAttribute("dir", direction);
}

function fileForLanguage(matches: Record<string, string>, lang: string) {
  if (Object.prototype.hasOwnProperty.call(matches, lang)) {
    return matches[lang];
  }
  return lang;
}

function vueI18NfileForLanguage(lang: string) {
  const matches: Record<string, string> = {
    fr: "fr_FR",
    en: "en_US",
  };
  return fileForLanguage(matches, lang);
}

export async function loadLanguageAsync(lang: string): Promise<string> {
  // If the same language
  if (i18n.global.locale === lang) {
    return Promise.resolve(setI18nLanguage(lang));
  }

  // If the language was already loaded
  if (loadedLanguages.includes(lang)) {
    return Promise.resolve(setI18nLanguage(lang));
  }
  // If the language hasn't been loaded yet
  const newMessages = await import(
    `../i18n/${vueI18NfileForLanguage(lang)}.json`
  );
  i18n.global.setLocaleMessage(lang, newMessages.default);
  loadedLanguages.push(lang);
  return setI18nLanguage(lang);
}

loadLanguageAsync(locale);

export function formatList(list: string[]): string {
  if (window.Intl && Intl.ListFormat) {
    const formatter = new Intl.ListFormat(undefined, {
      style: "long",
      type: "conjunction",
    });
    return formatter.format(list);
  }
  return list.join(",");
}
