import { createRouter, createWebHistory } from "vue-router";
import VueScrollTo from "vue-scrollto";
import HomeView from "../views/HomeView.vue";
import { eventRoutes } from "./event";
import { actorRoutes } from "./actor";
import { errorRoutes } from "./error";
import { authGuardIfNeeded } from "./guards/auth-guard";
import { settingsRoutes } from "./settings";
import { groupsRoutes } from "./groups";
import { discussionRoutes } from "./discussion";
import { conversationRoutes } from "./conversation";
import { userRoutes } from "./user";
import RouteName from "./name";
import { AVAILABLE_LANGUAGES, i18n } from "@/utils/i18n";

const { t } = i18n.global;

function scrollBehavior(to: any, from: any, savedPosition: any) {
  if (to.hash) {
    VueScrollTo.scrollTo(to.hash, 700);
    return {
      selector: to.hash,
      offset: { left: 0, top: 10 },
    };
  }
  if (savedPosition) {
    return savedPosition;
  }

  return { left: 0, top: 0 };
}

export const routes = [
  ...userRoutes,
  ...eventRoutes,
  ...settingsRoutes,
  ...actorRoutes,
  ...groupsRoutes,
  ...discussionRoutes,
  ...conversationRoutes,
  ...errorRoutes,
  {
    path: "/search",
    name: RouteName.SEARCH,
    component: (): Promise<any> => import("@/views/SearchView.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Search") as string },
    },
  },
  {
    path: "/",
    name: RouteName.HOME,
    component: HomeView,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Homepage") as string },
    },
  },
  {
    path: "/categories",
    name: RouteName.CATEGORIES,
    component: (): Promise<any> => import("@/views/CategoriesView.vue"),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Categories") as string },
    },
  },
  {
    path: "/about",
    name: RouteName.ABOUT,
    component: (): Promise<any> => import("@/views/AboutView.vue"),
    meta: { requiredAuth: false },
    redirect: { name: RouteName.ABOUT_INSTANCE },
    children: [
      {
        path: "instance",
        name: RouteName.ABOUT_INSTANCE,
        component: (): Promise<any> =>
          import("@/views/About/AboutInstanceView.vue"),
        meta: {
          announcer: {
            message: (): string => t("About instance") as string,
          },
        },
      },
      {
        path: "/terms",
        name: RouteName.TERMS,
        component: (): Promise<any> => import("@/views/About/TermsView.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => t("Terms") as string },
        },
      },
      {
        path: "/privacy",
        name: RouteName.PRIVACY,
        component: (): Promise<any> => import("@/views/About/PrivacyView.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => t("Privacy") as string },
        },
      },
      {
        path: "/rules",
        name: RouteName.RULES,
        component: (): Promise<any> => import("@/views/About/RulesView.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => t("Rules") as string },
        },
      },
      {
        path: "/glossary",
        name: RouteName.GLOSSARY,
        component: (): Promise<any> => import("@/views/About/GlossaryView.vue"),
        meta: {
          requiredAuth: false,
          announcer: { message: (): string => t("Glossary") as string },
        },
      },
    ],
  },
  {
    path: "/interact",
    name: RouteName.INTERACT,
    component: (): Promise<any> => import("@/views/InteractView.vue"),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Interact") as string },
    },
  },
  {
    path: "/auth/:provider/callback",
    name: "auth-callback",
    component: (): Promise<any> =>
      import("@/views/User/ProviderValidation.vue"),
    meta: {
      announcer: {
        message: (): string => t("Redirecting to Mobilizon") as string,
      },
    },
  },
  {
    path: "/welcome/:step?",
    name: RouteName.WELCOME_SCREEN,
    component: (): Promise<any> =>
      import(
        /* webpackChunkName: "WelcomeScreen" */ "@/views/User/SettingsOnboard.vue"
      ),
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => t("First steps") as string },
    },
    props: (route: any): Record<string, unknown> => {
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
    component: (): Promise<any> =>
      import(
        /* webpackChunkName: "PageNotFound" */ "../views/PageNotFound.vue"
      ),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Page not found") as string },
    },
  },
];

for (const locale of AVAILABLE_LANGUAGES) {
  routes.push({
    path: `/${locale}`,
    component: () =>
      import("../components/Utils/HomepageRedirectComponent.vue"),
  });
}

routes.push({
  path: "/:pathMatch(.*)*",
  redirect: { name: RouteName.PAGE_NOT_FOUND },
});

const router = createRouter({
  scrollBehavior,
  history: createWebHistory("/"),
  routes,
});

router.beforeEach(authGuardIfNeeded);
// router.afterEach(() => {
//   try {
//     if (router.app.$children[0]) {
//       // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//       // @ts-ignore
//       router.app.$children[0].error = null;
//     }
//   } catch (e) {
//     console.error(e);
//   }
// });

router.onError((error, to) => {
  if (
    error.message.includes("Failed to fetch dynamically imported module") ||
    error.message.includes("Importing a module script failed")
  ) {
    window.location.href = to.fullPath;
  }
});

export { router };
