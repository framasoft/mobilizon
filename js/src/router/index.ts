import Vue from 'vue';
import Router from 'vue-router';
import PageNotFound from '@/views/PageNotFound.vue';
import Home from '@/views/Home.vue';
import Event from '@/views/Event/Event.vue';
import EventList from '@/views/Event/EventList.vue';
import Location from '@/views/Location.vue';
import CreateEvent from '@/views/Event/Create.vue';
import CategoryList from '@/views/Category/List.vue';
import CreateCategory from '@/views/Category/Create.vue';
import Profile from '@/views/Account/Profile.vue';
import CreateGroup from '@/views/Group/Create.vue';
import Group from '@/views/Group/Group.vue';
import GroupList from '@/views/Group/GroupList.vue';
import Identities from '@/views/Account/Identities.vue';
import userRoutes from './user';

Vue.use(Router);

const router = new Router({
  mode: 'history',
  base: '/',
  routes: [
    ...userRoutes,
    {
      path: '/',
      name: 'Home',
      component: Home,
      meta: { requiredAuth: false },
    },
    {
      path: '/events/list/:location?',
      name: 'EventList',
      component: EventList,
      meta: { requiredAuth: false },
    },
    {
      path: '/events/create',
      name: 'CreateEvent',
      component: CreateEvent,
      meta: { requiredAuth: true },
    },
    {
      path: '/events/:id/edit',
      name: 'EditEvent',
      component: CreateEvent,
      props: true,
      meta: { requiredAuth: true },
    },
    {
      path: '/location/new',
      name: 'Location',
      component: Location,
      meta: { requiredAuth: true },
    },
    {
      path: '/category',
      name: 'CategoryList',
      component: CategoryList,
      meta: { requiredAuth: false },
    },
    {
      path: '/category/create',
      name: 'CreateCategory',
      component: CreateCategory,
      meta: { requiredAuth: true },
    },
    {
      path: '/identities',
      name: 'Identities',
      component: Identities,
      meta: { requiredAuth: true },
    },
    {
      path: '/groups',
      name: 'GroupList',
      component: GroupList,
      meta: { requiredAuth: false },
    },
    {
      path: '/groups/create',
      name: 'CreateGroup',
      component: CreateGroup,
      meta: { requiredAuth: true },
    },
    {
      path: '/~:name',
      name: 'Group',
      component: Group,
      props: true,
      meta: { requiredAuth: false },
    },
    {
      path: '/@:name',
      name: 'Profile',
      component: Profile,
      props: true,
      meta: { requiredAuth: false },
    },
    {
      path: '/events/:uuid',
      name: 'Event',
      component: Event,
      props: true,
      meta: { requiredAuth: false },
    },
    {
      path: '*',
      name: 'PageNotFound',
      component: PageNotFound,
      meta: { requiredAuth: false },
    },
  ],
});

export default router;
