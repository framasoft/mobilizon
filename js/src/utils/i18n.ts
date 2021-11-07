import Vue from "vue";
import VueI18n from "vue-i18n";
import { DateFnsPlugin } from "@/plugins/dateFns";
import en from "../i18n/en_US.json";
import langs from "../i18n/langs.json";
import { getLocaleData } from "./auth";
import pluralizationRules from "../i18n/pluralRules";

const DEFAULT_LOCALE = "en_US";

const localeInLocalStorage = getLocaleData();

console.debug("localeInLocalStorage", localeInLocalStorage);

let language =
  localeInLocalStorage ||
  (document.documentElement.getAttribute("lang") as string);

console.debug(
  "localeInLocalStorage or fallback to lang html attribute",
  language
);

language =
  language ||
  ((window.navigator as any).userLanguage || window.navigator.language).replace(
    /-/,
    "_"
  );

console.debug("language or fallback to window.navigator language", language);

export const locale =
  language && Object.prototype.hasOwnProperty.call(langs, language)
    ? language
    : language.split("-")[0];

console.debug("chosen locale", locale);

Vue.use(VueI18n);

export const i18n = new VueI18n({
  locale: DEFAULT_LOCALE, // set locale
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  messages: en, // set locale messages
  fallbackLocale: DEFAULT_LOCALE,
  formatFallbackMessages: true,
  pluralizationRules,
});

console.debug("set VueI18n with default locale", DEFAULT_LOCALE);

const loadedLanguages = [DEFAULT_LOCALE];

function setI18nLanguage(lang: string): string {
  console.debug("setting i18n locale to", lang);
  i18n.locale = lang;
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
  console.debug("setDirection with", [fixedLang, direction]);
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

function dateFnsfileForLanguage(lang: string) {
  const matches: Record<string, string> = {
    en_US: "en-US",
    en: "en-US",
  };
  return fileForLanguage(matches, lang);
}

Vue.use(DateFnsPlugin, { locale: dateFnsfileForLanguage(locale) });

export async function loadLanguageAsync(lang: string): Promise<string> {
  // If the same language
  if (i18n.locale === lang) {
    console.debug("already using language", lang);
    return Promise.resolve(setI18nLanguage(lang));
  }

  // If the language was already loaded
  if (loadedLanguages.includes(lang)) {
    console.debug("language already loaded", lang);
    return Promise.resolve(setI18nLanguage(lang));
  }
  // If the language hasn't been loaded yet
  console.debug("loading language", lang);
  const newMessages = await import(
    /* webpackChunkName: "lang-[request]" */ `@/i18n/${vueI18NfileForLanguage(
      lang
    )}.json`
  );
  i18n.setLocaleMessage(lang, newMessages.default);
  loadedLanguages.push(lang);
  return setI18nLanguage(lang);
}

console.debug("loading async locale", locale);
loadLanguageAsync(locale);
console.debug("loaded async locale", locale);

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
