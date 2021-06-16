import { RouteConfig } from "vue-router";
import { ImportedComponent } from "vue/types/options";

export enum ErrorRouteName {
  ERROR = "Error",
}

export const errorRoutes: RouteConfig[] = [
  {
    path: "/error",
    name: ErrorRouteName.ERROR,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Error" */ "../views/Error.vue"),
  },
];
