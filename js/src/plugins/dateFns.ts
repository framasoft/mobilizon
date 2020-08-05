import Vue from "vue";
import Locale from "date-fns";

declare module "vue/types/vue" {
  interface Vue {
    $dateFnsLocale: Locale;
  }
}

export function DateFnsPlugin(vue: typeof Vue, { locale }: { locale: string }): void {
  import(`date-fns/locale/${locale}/index.js`).then((localeEntity) => {
    Vue.prototype.$dateFnsLocale = localeEntity;
  });
}
