import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { RouteConfig } from "vue-router";
import { EsModuleComponent } from "vue/types/options";

export enum ErrorRouteName {
  ERROR = "Error",
}

export const errorRoutes: RouteConfig[] = [
  {
    path: "/error",
    name: ErrorRouteName.ERROR,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "Error" */ "../views/Error.vue"),
    beforeEnter: beforeRegisterGuard,
  },
];
