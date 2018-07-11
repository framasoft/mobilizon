import Vue from 'vue';
import Router from 'vue-router';
import PageNotFound from '@/components/PageNotFound';
import Home from '@/components/Home';
import Event from '@/components/Event/Event';
import EventList from '@/components/Event/EventList';
import Location from '@/components/Location';
import CreateEvent from '@/components/Event/Create';
import CategoryList from '@/components/Category/List';
import CreateCategory from '@/components/Category/Create';
import Register from '@/components/Account/Register';
import Login from '@/components/Account/Login';
import Validate from '@/components/Account/Validate';
import ResendConfirmation from '@/components/Account/ResendConfirmation';
import SendPasswordReset from '@/components/Account/SendPasswordReset';
import PasswordReset from '@/components/Account/PasswordReset';
import Account from '@/components/Account/Account';
import CreateGroup from '@/components/Group/Create';
import Group from '@/components/Group/Group';
import GroupList from '@/components/Group/GroupList';
import Identities from '../components/Account/Identities.vue';

Vue.use(Router);

const router = new Router({
  mode: 'history',
  base: '/',
  routes: [
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
      path: '/events/:id(\\d+)/edit',
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
      path: '/register',
      name: 'Register',
      component: Register,
      props: true,
      meta: { requiredAuth: false },
    },
    {
      path: '/resend-instructions',
      name: 'ResendConfirmation',
      component: ResendConfirmation,
      props: true,
      meta: { requiresAuth: false },
    },
    {
      path: '/password-reset/send',
      name: 'SendPasswordReset',
      component: SendPasswordReset,
      props: true,
      meta: { requiresAuth: false },
    },
    {
      path: '/password-reset/:token',
      name: 'PasswordReset',
      component: PasswordReset,
      meta: { requiresAuth: false },
      props: true,
    },
    {
      path: '/validate/:token',
      name: 'Validate',
      component: Validate,
      props: true,
      meta: { requiresAuth: false },
    },
    {
      path: '/login',
      name: 'Login',
      component: Login,
      props: true,
      meta: { requiredAuth: false },
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
      path: '/group-create',
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
      name: 'Account',
      component: Account,
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
