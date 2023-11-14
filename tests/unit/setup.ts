import "./specs/mocks/matchMedia";
import { config } from "@vue/test-utils";
import { createHead } from "@vueuse/head";
import { createI18n } from "vue-i18n";
import en_US from "@/i18n/en_US.json";

const i18n = createI18n({
  legacy: false,
  messages: { en_US },
  locale: "en_US",
});

const head = createHead();

config.global.plugins.push(head);
config.global.plugins.push(i18n);
