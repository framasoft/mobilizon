import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { RouteConfig } from "vue-router";
import ErrorPage from "../views/Error.vue";

export enum ErrorRouteName {
  ERROR = "Error",
}

export const errorRoutes: RouteConfig[] = [
  {
    path: "/error",
    name: ErrorRouteName.ERROR,
    component: ErrorPage,
    beforeEnter: beforeRegisterGuard,
  },
];
