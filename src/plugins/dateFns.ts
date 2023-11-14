import type { Locale } from "date-fns";
import { App } from "vue";

export const dateFnsPlugin = {
  install(app: App, options: { locale: string }) {
    function dateFnsfileForLanguage(lang: string) {
      const matches: Record<string, string> = {
        en: "en-US",
      };
      return matches[lang] ?? lang.replace("_", "-");
    }

    import(
      `../../node_modules/date-fns/esm/locale/${dateFnsfileForLanguage(
        options.locale
      )}/index.js`
    ).then((localeEntity: { default: Locale }) => {
      app.provide("dateFnsLocale", localeEntity.default);
      app.config.globalProperties.$dateFnsLocale = localeEntity.default;
    });
  },
};
