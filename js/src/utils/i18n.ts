import Vue from "vue";
import VueI18n from "vue-i18n";
import { DateFnsPlugin } from "@/plugins/dateFns";
import en from "../i18n/en_US.json";
import langs from "../i18n/langs.json";

const DEFAULT_LOCALE = "en";

let language = document.documentElement.getAttribute("lang") as string;
language = language || ((window.navigator as any).userLanguage || window.navigator.language).replace(/-/, "_");
export const locale =
  language && Object.prototype.hasOwnProperty.call(langs, language) ? language : language.split("-")[0];

Vue.use(VueI18n);

console.log(en);
console.log(locale);
export const i18n = new VueI18n({
  locale: DEFAULT_LOCALE, // set locale
  messages: (en as unknown) as VueI18n.LocaleMessages, // set locale messages
  fallbackLocale: "en",
});
console.log(i18n);

Vue.use(DateFnsPlugin, { locale });

const loadedLanguages = ["en"];

function setI18nLanguage(lang: string): string {
  i18n.locale = lang;
  return lang;
}

function fileForLanguage(lang: string) {
  const matches: Record<string, string> = {
    fr: "fr_FR",
    en: "en_US",
  };
  if (Object.prototype.hasOwnProperty.call(matches, lang)) {
    return matches[lang];
  }
  return lang;
}

export async function loadLanguageAsync(lang: string): Promise<string> {
  // If the same language
  if (i18n.locale === lang) {
    return Promise.resolve(setI18nLanguage(lang));
  }

  // If the language was already loaded
  if (loadedLanguages.includes(lang)) {
    return Promise.resolve(setI18nLanguage(lang));
  }

  console.log(fileForLanguage(lang));
  // If the language hasn't been loaded yet
  return import(/* webpackChunkName: "lang-[request]" */ `@/i18n/${fileForLanguage(lang)}.json`).then(
    (newMessages: any) => {
      i18n.setLocaleMessage(lang, newMessages.default);
      loadedLanguages.push(lang);
      return setI18nLanguage(lang);
    }
  );
}

loadLanguageAsync(locale);

export function formatList(list: string[]): string {
  if (window.Intl && Intl.ListFormat) {
    const formatter = new Intl.ListFormat(undefined, { style: "long", type: "conjunction" });
    return formatter.format(list);
  }
  return list.join(",");
}
