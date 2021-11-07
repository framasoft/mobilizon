import Vue from "vue";
import Router, { Route } from "vue-router";
import VueScrollTo from "vue-scrollto";
import { PositionResult } from "vue-router/types/router.d";
import { ImportedComponent } from "vue/types/options";
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
import { AVAILABLE_LANGUAGES, i18n } from "@/utils/i18n";

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
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Search" */ "@/views/Search.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Search") as string },
    },
  },
  {
    path: "/",
    name: RouteName.HOME,
    component: Home,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Homepage") as string },
    },
  },
  {
    path: "/about",
    name: RouteName.ABOUT,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "about" */ "@/views/About.vue"),
    meta: { requiredAuth: false },
    redirect: { name: RouteName.ABOUT_INSTANCE },
    children: [
      {
        path: "instance",
        name: RouteName.ABOUT_INSTANCE,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "about" */ "@/views/About/AboutInstance.vue"
          ),
        meta: {
          announcer: {
            message: (): string => i18n.t("About instance") as string,
          },
        },
      },
      {
        path: "/terms",
        name: RouteName.TERMS,
        component: (): Promise<ImportedComponent> =>
          import(/* webpackChunkName: "cookies" */ "@/views/About/Terms.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => i18n.t("Terms") as string },
        },
      },
      {
        path: "/privacy",
        name: RouteName.PRIVACY,
        component: (): Promise<ImportedComponent> =>
          import(/* webpackChunkName: "cookies" */ "@/views/About/Privacy.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => i18n.t("Privacy") as string },
        },
      },
      {
        path: "/rules",
        name: RouteName.RULES,
        component: (): Promise<ImportedComponent> =>
          import(/* webpackChunkName: "cookies" */ "@/views/About/Rules.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => i18n.t("Rules") as string },
        },
      },
      {
        path: "/glossary",
        name: RouteName.GLOSSARY,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "cookies" */ "@/views/About/Glossary.vue"
          ),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => i18n.t("Glossary") as string },
        },
      },
    ],
  },
  {
    path: "/interact",
    name: RouteName.INTERACT,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "interact" */ "@/views/Interact.vue"),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Interact") as string },
    },
  },
  {
    path: "/auth/:provider/callback",
    name: "auth-callback",
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "ProviderValidation" */ "@/views/User/ProviderValidation.vue"
      ),
    meta: {
      announcer: {
        message: (): string => i18n.t("Redirecting to Mobilizon") as string,
      },
    },
  },
  {
    path: "/welcome/:step?",
    name: RouteName.WELCOME_SCREEN,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "WelcomeScreen" */ "@/views/User/SettingsOnboard.vue"
      ),
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => i18n.t("First steps") as string },
    },
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
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "PageNotFound" */ "../views/PageNotFound.vue"
      ),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Page not found") as string },
    },
  },
];

for (const locale of AVAILABLE_LANGUAGES) {
  routes.push({
    path: `/${locale}`,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "HomepageRedirectComponent" */ "../components/Utils/HomepageRedirectComponent.vue"
      ),
  });
}

routes.push({
  path: "*",
  redirect: { name: RouteName.PAGE_NOT_FOUND },
});

const router = new Router({
  scrollBehavior,
  mode: "history",
  base: "/",
  routes,
});

router.beforeEach(authGuardIfNeeded);
router.afterEach(() => {
  try {
    if (router.app.$children[0]) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      router.app.$children[0].error = null;
    }
  } catch (e) {
    console.error(e);
  }
});

export default router;
