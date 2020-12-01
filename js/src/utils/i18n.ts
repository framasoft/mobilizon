import Vue from "vue";
import VueI18n from "vue-i18n";
import { DateFnsPlugin } from "@/plugins/dateFns";
import en from "../i18n/en_US.json";
import langs from "../i18n/langs.json";
import { getLocaleData } from "./auth";

const DEFAULT_LOCALE = "en_US";

let language =
  getLocaleData() || (document.documentElement.getAttribute("lang") as string);

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

Vue.use(VueI18n);

export const i18n = new VueI18n({
  locale: DEFAULT_LOCALE, // set locale
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  messages: en, // set locale messages
  fallbackLocale: DEFAULT_LOCALE,
  formatFallbackMessages: true,
});

const loadedLanguages = [DEFAULT_LOCALE];

function setI18nLanguage(lang: string): string {
  i18n.locale = lang;
  return lang;
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
    return Promise.resolve(setI18nLanguage(lang));
  }

  // If the language was already loaded
  if (loadedLanguages.includes(lang)) {
    return Promise.resolve(setI18nLanguage(lang));
  }
  // If the language hasn't been loaded yet
  const newMessages = await import(
    /* webpackChunkName: "lang-[request]" */ `@/i18n/${vueI18NfileForLanguage(
      lang
    )}.json`
  );
  i18n.setLocaleMessage(lang, newMessages.default);
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
