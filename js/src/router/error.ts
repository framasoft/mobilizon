import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { RouteConfig } from "vue-router";

export enum ErrorRouteName {
  ERROR = "Error",
}

export const errorRoutes: RouteConfig[] = [
  {
    path: "/error",
    name: ErrorRouteName.ERROR,
    component: () => import(/* webpackChunkName: "Error" */ "../views/Error.vue"),
    beforeEnter: beforeRegisterGuard,
  },
];
