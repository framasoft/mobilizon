import Vue from "vue";
import Router, { Route } from "vue-router";
import VueScrollTo from "vue-scrollto";
import { PositionResult } from "vue-router/types/router.d";
import { EsModuleComponent } from "vue/types/options";
import Home from "../views/Home.vue";
import { eventRoutes } from "./event";
import { actorRoutes } from "./actor";
import { errorRoutes } from "./error";
import { authGuardIfNeeded } from "./guards/auth-guard";
import { settingsRoutes } from "./settings";
import { groupsRoutes } from "./groups";
import { discussionRoutes } from "./discussion";
import { userRoutes } from "./user";
import RouteName from "./name";

Vue.use(Router);

function scrollBehavior(
  to: Route,
  from: Route,
  savedPosition: any
): PositionResult | undefined | null {
  if (to.hash) {
    VueScrollTo.scrollTo(to.hash, 700);
    return {
      selector: to.hash,
      offset: { x: 0, y: 10 },
    };
  }
  if (savedPosition) {
    return savedPosition;
  }

  return { x: 0, y: 0 };
}

export const routes = [
  ...userRoutes,
  ...eventRoutes,
  ...settingsRoutes,
  ...actorRoutes,
  ...groupsRoutes,
  ...discussionRoutes,
  ...errorRoutes,
  {
    path: "/search",
    name: RouteName.SEARCH,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "search" */ "../views/Search.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/",
    name: RouteName.HOME,
    component: Home,
    meta: { requiredAuth: false },
  },
  {
    path: "/about",
    name: RouteName.ABOUT,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "about" */ "@/views/About.vue"),
    meta: { requiredAuth: false },
    redirect: { name: RouteName.ABOUT_INSTANCE },
    children: [
      {
        path: "instance",
        name: RouteName.ABOUT_INSTANCE,
        component: (): Promise<EsModuleComponent> =>
          import(
            /* webpackChunkName: "about" */ "@/views/About/AboutInstance.vue"
          ),
      },
      {
        path: "/terms",
        name: RouteName.TERMS,
        component: (): Promise<EsModuleComponent> =>
          import(/* webpackChunkName: "cookies" */ "@/views/About/Terms.vue"),
        meta: { requiredAuth: false },
      },
      {
        path: "/privacy",
        name: RouteName.PRIVACY,
        component: (): Promise<EsModuleComponent> =>
          import(/* webpackChunkName: "cookies" */ "@/views/About/Privacy.vue"),
        meta: { requiredAuth: false },
      },
      {
        path: "/rules",
        name: RouteName.RULES,
        component: (): Promise<EsModuleComponent> =>
          import(/* webpackChunkName: "cookies" */ "@/views/About/Rules.vue"),
        meta: { requiredAuth: false },
      },
      {
        path: "/glossary",
        name: RouteName.GLOSSARY,
        component: (): Promise<EsModuleComponent> =>
          import(
            /* webpackChunkName: "cookies" */ "@/views/About/Glossary.vue"
          ),
        meta: { requiredAuth: false },
      },
    ],
  },
  {
    path: "/interact",
    name: RouteName.INTERACT,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "cookies" */ "@/views/Interact.vue"),
    meta: { requiredAuth: false },
  },
  {
    path: "/auth/:provider/callback",
    name: "auth-callback",
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "ProviderValidation" */ "@/views/User/ProviderValidation.vue"
      ),
  },
  {
    path: "/welcome/:step?",
    name: RouteName.WELCOME_SCREEN,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "WelcomeScreen" */ "@/views/User/SettingsOnboard.vue"
      ),
    meta: { requiredAuth: true },
    props: (route: Route): Record<string, unknown> => {
      const step = Number.parseInt(route.params.step, 10);
      if (Number.isNaN(step)) {
        return { step: 1 };
      }
      return { step };
    },
  },
  {
    path: "/404",
    name: RouteName.PAGE_NOT_FOUND,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "search" */ "../views/PageNotFound.vue"),
    meta: { requiredAuth: false },
  },
  {
    path: "*",
    redirect: { name: RouteName.PAGE_NOT_FOUND },
  },
];

const router = new Router({
  scrollBehavior,
  mode: "history",
  base: "/",
  routes,
});

router.beforeEach(authGuardIfNeeded);
router.afterEach(() => {
  if (router.app.$children[0]) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    router.app.$children[0].error = null;
  }
});

export default router;
