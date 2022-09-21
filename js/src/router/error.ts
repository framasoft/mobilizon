import { RouteRecordRaw } from "vue-router";
import { i18n } from "@/utils/i18n";

const { t } = i18n.global.t;

export enum ErrorRouteName {
  ERROR = "Error",
}

export const errorRoutes: RouteRecordRaw[] = [
  {
    path: "/error",
    name: ErrorRouteName.ERROR,
    component: (): Promise<any> => import("../views/ErrorView.vue"),
    meta: {
      announcer: { message: (): string => t("Error") },
    },
  },
];
