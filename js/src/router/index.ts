import Vue from 'vue';
import Router from 'vue-router';
import PageNotFound from '@/views/PageNotFound.vue';
import Home from '@/views/Home.vue';
import { UserRouteName, userRoutes } from './user';
import { EventRouteName, eventRoutes } from '@/router/event';
import { ActorRouteName, actorRoutes } from '@/router/actor';
import { ErrorRouteName, errorRoutes } from '@/router/error';
import { authGuardIfNeeded } from '@/router/guards/auth-guard';

Vue.use(Router);

enum GlobalRouteName {
  HOME = 'Home',
  PAGE_NOT_FOUND = 'PageNotFound',
}

// Hack to merge enums
// tslint:disable:variable-name
export const RouteName = {
  ...GlobalRouteName,
  ...UserRouteName,
  ...EventRouteName,
  ...ActorRouteName,
  ...ErrorRouteName,
};

const router = new Router({
  mode: 'history',
  base: '/',
  routes: [
    ...userRoutes,
    ...eventRoutes,
    ...actorRoutes,
    ...errorRoutes,

    {
      path: '/',
      name: RouteName.HOME,
      component: Home,
      meta: { requiredAuth: false },
    },

    {
      path: '*',
      name: RouteName.PAGE_NOT_FOUND,
      component: PageNotFound,
      meta: { requiredAuth: false },
    },
  ],
});

router.beforeEach(authGuardIfNeeded);

export default router;
