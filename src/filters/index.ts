import nl2br from "@/filters/utils";
import {
  formatDateString,
  formatTimeString,
  formatDateTimeString,
} from "./datetime";

export default {
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  install(vue: any): void {
    vue.filter("formatDateString", formatDateString);
    vue.filter("formatTimeString", formatTimeString);
    vue.filter("formatDateTimeString", formatDateTimeString);
    vue.filter("nl2br", nl2br);
  },
};
