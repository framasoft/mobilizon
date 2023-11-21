import "./specs/mocks/matchMedia";
import { config } from "@vue/test-utils";
import { createHead } from "@unhead/vue";
import { i18n } from "@/utils/i18n";

const head = createHead();

config.global.plugins.push(head);
config.global.plugins.push(i18n);
