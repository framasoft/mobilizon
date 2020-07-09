import Vue from "vue";
import Router, { Route } from "vue-router";
import VueScrollTo from "vue-scrollto";
import { PositionResult } from "vue-router/types/router.d";
import PageNotFound from "../views/PageNotFound.vue";
import Home from "../views/Home.vue";
import { eventRoutes } from "./event";
import { actorRoutes } from "./actor";
import { errorRoutes } from "./error";
import { authGuardIfNeeded } from "./guards/auth-guard";
import Search from "../views/Search.vue";
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

const router = new Router({
  scrollBehavior,
  mode: "history",
  base: "/",
  routes: [
    ...userRoutes,
    ...eventRoutes,
    ...settingsRoutes,
    ...actorRoutes,
    ...groupsRoutes,
    ...discussionRoutes,
    ...errorRoutes,
    {
      path: "/search/:searchTerm/:searchType?",
      name: RouteName.SEARCH,
      component: Search,
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
      component: () => import(/* webpackChunkName: "about" */ "@/views/About.vue"),
      meta: { requiredAuth: false },
      redirect: { name: RouteName.ABOUT_INSTANCE },
      children: [
        {
          path: "mobilizon",
          name: RouteName.ABOUT_MOBILIZON,
          component: () =>
            import(/* webpackChunkName: "about" */ "@/views/About/AboutMobilizon.vue"),
        },
        {
          path: "instance",
          name: RouteName.ABOUT_INSTANCE,
          component: () =>
            import(/* webpackChunkName: "about" */ "@/views/About/AboutInstance.vue"),
        },
        {
          path: "/terms",
          name: RouteName.TERMS,
          component: () => import(/* webpackChunkName: "cookies" */ "@/views/About/Terms.vue"),
          meta: { requiredAuth: false },
        },
        {
          path: "/privacy",
          name: RouteName.PRIVACY,
          component: () => import(/* webpackChunkName: "cookies" */ "@/views/About/Privacy.vue"),
          meta: { requiredAuth: false },
        },
        {
          path: "/rules",
          name: RouteName.RULES,
          component: () => import(/* webpackChunkName: "cookies" */ "@/views/About/Rules.vue"),
          meta: { requiredAuth: false },
        },
        {
          path: "/glossary",
          name: RouteName.GLOSSARY,
          component: () => import(/* webpackChunkName: "cookies" */ "@/views/About/Glossary.vue"),
          meta: { requiredAuth: false },
        },
      ],
    },
    {
      path: "/interact",
      name: RouteName.INTERACT,
      component: () => import(/* webpackChunkName: "cookies" */ "@/views/Interact.vue"),
      meta: { requiredAuth: false },
    },
    {
      path: "/auth/:provider/callback",
      name: "auth-callback",
      component: () => import("@/views/User/ProviderValidation.vue"),
    },
    {
      path: "/404",
      name: RouteName.PAGE_NOT_FOUND,
      component: PageNotFound,
      meta: { requiredAuth: false },
    },
    {
      path: "*",
      redirect: { name: RouteName.PAGE_NOT_FOUND },
    },
  ],
});

router.beforeEach(authGuardIfNeeded);

export default router;
