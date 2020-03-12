import { RouteConfig } from 'vue-router';
import Settings from '@/views/Settings.vue';
import AccountSettings from '@/views/Settings/AccountSettings.vue';
import Preferences from '@/views/Settings/Preferences.vue';
import Notifications from '@/views/Settings/Notifications.vue';
import Dashboard from '@/views/Admin/Dashboard.vue';
import AdminSettings from '@/views/Admin/Settings.vue';
import Follows from '@/views/Admin/Follows.vue';
import Followings from '@/components/Admin/Followings.vue';
import Followers from '@/components/Admin/Followers.vue';
import ReportList from '@/views/Moderation/ReportList.vue';
import Report from '@/views/Moderation/Report.vue';
import Logs from '@/views/Moderation/Logs.vue';
import EditIdentity from '@/views/Account/children/EditIdentity.vue';


export enum SettingsRouteName {
    SETTINGS = 'SETTINGS',
    ACCOUNT_SETTINGS = 'ACCOUNT_SETTINGS',
    ACCOUNT_SETTINGS_GENERAL = 'ACCOUNT_SETTINGS_GENERAL',
    PREFERENCES = 'PREFERENCES',
    NOTIFICATIONS = 'NOTIFICATIONS',
    ADMIN = 'ADMIN',
    ADMIN_DASHBOARD = 'ADMIN_DASHBOARD',
    ADMIN_SETTINGS = 'ADMIN_SETTINGS',
    RELAYS = 'Relays',
    RELAY_FOLLOWINGS = 'Followings',
    RELAY_FOLLOWERS = 'Followers',
    MODERATION = 'MODERATION',
    REPORTS = 'Reports',
    REPORT = 'Report',
    REPORT_LOGS = 'Logs',
    CREATE_IDENTITY = 'CreateIdentity',
    UPDATE_IDENTITY = 'UpdateIdentity',
    IDENTITIES = 'IDENTITIES',
}

export const settingsRoutes: RouteConfig[] = [
  {
    path: '/settings',
    component: Settings,
    props: true,
    meta: { requiredAuth: true },
    redirect: { name: SettingsRouteName.ACCOUNT_SETTINGS },
    name: SettingsRouteName.SETTINGS,
    children: [
      {
        path: 'account',
        name: SettingsRouteName.ACCOUNT_SETTINGS,
        redirect: { name: SettingsRouteName.ACCOUNT_SETTINGS_GENERAL },
      },
      {
        path: 'account/general',
        name: SettingsRouteName.ACCOUNT_SETTINGS_GENERAL,
        component: AccountSettings,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: 'preferences',
        name: SettingsRouteName.PREFERENCES,
        component: Preferences,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: 'notifications',
        name: SettingsRouteName.NOTIFICATIONS,
        component: Notifications,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: 'admin',
        name: SettingsRouteName.ADMIN,
        redirect: { name: SettingsRouteName.ADMIN_DASHBOARD },
      },
      {
        path: 'admin/dashboard',
        name: SettingsRouteName.ADMIN_DASHBOARD,
        component: Dashboard,
        meta: { requiredAuth: true },
      },
      {
        path: 'admin/settings',
        name: SettingsRouteName.ADMIN_SETTINGS,
        component: AdminSettings,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: 'admin/relays',
        name: SettingsRouteName.RELAYS,
        redirect: { name: SettingsRouteName.RELAY_FOLLOWINGS },
        component: Follows,
        children: [
          {
            path: 'followings',
            name: SettingsRouteName.RELAY_FOLLOWINGS,
            component: Followings,
          },
          {
            path: 'followers',
            name: SettingsRouteName.RELAY_FOLLOWERS,
            component: Followers,
          },
        ],
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: '/moderation',
        name: SettingsRouteName.MODERATION,
        redirect: { name: SettingsRouteName.REPORTS },
      },
      {
        path: '/moderation/reports/:filter?',
        name: SettingsRouteName.REPORTS,
        component: ReportList,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: '/moderation/report/:reportId',
        name: SettingsRouteName.REPORT,
        component: Report,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: '/moderation/logs',
        name: SettingsRouteName.REPORT_LOGS,
        component: Logs,
        props: true,
        meta: { requiredAuth: true },
      },
      {
        path: '/identity',
        name: SettingsRouteName.IDENTITIES,
        redirect: { name: SettingsRouteName.UPDATE_IDENTITY },
      },
      {
        path: '/identity/create',
        name: SettingsRouteName.CREATE_IDENTITY,
        component: EditIdentity,
        props: (route) => ({ identityName: route.params.identityName, isUpdate: false }),
      },
      {
        path: '/identity/update/:identityName?',
        name: SettingsRouteName.UPDATE_IDENTITY,
        component: EditIdentity,
        props: (route) => ({ identityName: route.params.identityName, isUpdate: true }),
      },
    ],
  },
];
