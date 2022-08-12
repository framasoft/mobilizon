import { defineSetupVue3 } from "@histoire/plugin-vue";
import { orugaConfig } from "./oruga-config";
import { i18n } from "./utils/i18n";
import Oruga from "@oruga-ui/oruga-next";
import "@oruga-ui/oruga-next/dist/oruga-full-vars.css";
import "./assets/tailwind.css";
import "./assets/oruga-tailwindcss.css";
import locale from "date-fns/locale/en-US";
import MaterialIcon from "./components/core/MaterialIcon.vue";

export const setupVue3 = defineSetupVue3(({ app }) => {
  // Vue plugin
  app.use(i18n);
  app.use(Oruga, orugaConfig);
  app.component("material-icon", MaterialIcon);
  app.provide("dateFnsLocale", locale);
});
