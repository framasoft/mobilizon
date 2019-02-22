import Vue from 'vue';
import Router from 'vue-router';
import PageNotFound from '@/views/PageNotFound.vue';
import Home from '@/views/Home.vue';
import { UserRouteName, userRoutes } from './user';
import { EventRouteName, eventRoutes } from '@/router/event';
import { ActorRouteName, actorRoutes } from '@/router/actor';
import { CategoryRouteName, categoryRoutes } from '@/router/category';

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
  ...CategoryRouteName,
  ...ActorRouteName,
};

const router = new Router({
  mode: 'history',
  base: '/',
  routes: [
    ...userRoutes,
    ...eventRoutes,
    ...categoryRoutes,
    ...actorRoutes,

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

export default router;
