import Vue from "vue";
import VueI18n from "vue-i18n";
import messages from "../i18n/index";

let language = document.documentElement.getAttribute("lang") as string;
language = language || ((window.navigator as any).userLanguage || window.navigator.language).replace(/-/, "_");
export const locale = language && messages.hasOwnProperty(language) ? language : language.split("-")[0];

Vue.use(VueI18n);

export const i18n = new VueI18n({
  locale, // set locale
  messages, // set locale messages
  fallbackLocale: "en_US",
});

export function formatList(list: string[]): string {
  if (window.Intl && Intl.ListFormat) {
    const formatter = new Intl.ListFormat(undefined, { style: "long", type: "conjunction" });
    return formatter.format(list);
  }
  return list.join(",");
}
