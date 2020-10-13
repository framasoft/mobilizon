import nl2br from "@/filters/utils";
import { formatDateString, formatTimeString, formatDateTimeString } from "./datetime";

export default {
  install(vue: any): void {
    vue.filter("formatDateString", formatDateString);
    vue.filter("formatTimeString", formatTimeString);
    vue.filter("formatDateTimeString", formatDateTimeString);
    vue.filter("nl2br", nl2br);
  },
};
