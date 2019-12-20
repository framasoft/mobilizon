import Vue from 'vue';
import Router from 'vue-router';
import VueScrollTo from 'vue-scrollto';
import PageNotFound from '@/views/PageNotFound.vue';
import Home from '@/views/Home.vue';
import { UserRouteName, userRoutes } from './user';
import { EventRouteName, eventRoutes } from '@/router/event';
import { ActorRouteName, actorRoutes, MyAccountRouteName } from '@/router/actor';
import { AdminRouteName, adminRoutes } from '@/router/admin';
import { ErrorRouteName, errorRoutes } from '@/router/error';
import { authGuardIfNeeded } from '@/router/guards/auth-guard';
import Search from '@/views/Search.vue';
import { ModerationRouteName, moderationRoutes } from '@/router/moderation';

Vue.use(Router);

enum GlobalRouteName {
  HOME = 'Home',
  ABOUT = 'About',
  PAGE_NOT_FOUND = 'PageNotFound',
  SEARCH = 'Search',
  TERMS = 'TERMS',
  INTERACT = 'INTERACT',
}

function scrollBehavior(to, from, savedPosition) {
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

// Hack to merge enums
// tslint:disable:variable-name
export const RouteName = {
  ...GlobalRouteName,
  ...UserRouteName,
  ...EventRouteName,
  ...ActorRouteName,
  ...MyAccountRouteName,
  ...AdminRouteName,
  ...ModerationRouteName,
  ...ErrorRouteName,
};

const router = new Router({
  scrollBehavior,
  mode: 'history',
  base: '/',
  routes: [
    ...userRoutes,
    ...eventRoutes,
    ...actorRoutes,
    ...adminRoutes,
    ...moderationRoutes,
    ...errorRoutes,
    {
      path: '/search/:searchTerm/:searchType?',
      name: RouteName.SEARCH,
      component: Search,
      props: true,
      meta: { requiredAuth: false },
    },
    {
      path: '/',
      name: RouteName.HOME,
      component: Home,
      meta: { requiredAuth: false },
    },
    {
      path: '/about',
      name: RouteName.ABOUT,
      component: () => import(/* webpackChunkName: "about" */ '@/views/About.vue'),
      meta: { requiredAuth: false },
    },
    {
      path: '/terms',
      name: RouteName.TERMS,
      component: () => import(/* webpackChunkName: "cookies" */ '@/views/Terms.vue'),
      meta: { requiredAuth: false },
    },
    {
      path: '/interact',
      name: RouteName.INTERACT,
      component: () => import(/* webpackChunkName: "cookies" */ '@/views/Interact.vue'),
      meta: { requiredAuth: false },
    },
    {
      path: '/404',
      name: RouteName.PAGE_NOT_FOUND,
      component: PageNotFound,
      meta: { requiredAuth: false },
    },
    {
      path: '*',
      redirect: { name: RouteName.PAGE_NOT_FOUND },
    },
  ],
});

router.beforeEach(authGuardIfNeeded);

export default router;
