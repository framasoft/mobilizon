import { RouteConfig } from 'vue-router';
import Dashboard from '@/views/Admin/Dashboard.vue';

export enum AdminRouteName {
  DASHBOARD = 'Dashboard',
}

export const adminRoutes: RouteConfig[] = [
  {
    path: '/admin',
    name: AdminRouteName.DASHBOARD,
    component: Dashboard,
    props: true,
    meta: { requiredAuth: true },
  },
];
