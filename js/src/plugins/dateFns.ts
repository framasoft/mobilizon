import Locale from "date-fns";
import VueInstance from "vue";

declare module "vue/types/vue" {
  interface Vue {
    $dateFnsLocale: Locale;
  }
}

export function DateFnsPlugin(
  vue: typeof VueInstance,
  { locale }: { locale: string }
): void {
  import(`date-fns/locale/${locale}/index.js`).then((localeEntity) => {
    VueInstance.prototype.$dateFnsLocale = localeEntity;
  });
}
