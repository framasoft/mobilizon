import { RouteConfig } from "vue-router";
import { ImportedComponent } from "vue/types/options";
import { i18n } from "@/utils/i18n";

export enum ErrorRouteName {
  ERROR = "Error",
}

export const errorRoutes: RouteConfig[] = [
  {
    path: "/error",
    name: ErrorRouteName.ERROR,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Error" */ "../views/Error.vue"),
    meta: {
      announcer: { message: (): string => i18n.t("Error") as string },
    },
  },
];
