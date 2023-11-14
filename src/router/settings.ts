import { i18n } from "@/utils/i18n";
import { RouteLocationNormalized, RouteRecordRaw } from "vue-router";

const { t } = i18n.global;

export enum SettingsRouteName {
  SETTINGS = "SETTINGS",
  ACCOUNT_SETTINGS = "ACCOUNT_SETTINGS",
  ACCOUNT_SETTINGS_GENERAL = "ACCOUNT_SETTINGS_GENERAL",
  PREFERENCES = "PREFERENCES",
  NOTIFICATIONS = "NOTIFICATIONS",
  ADMIN = "ADMIN",
  ADMIN_DASHBOARD = "ADMIN_DASHBOARD",
  ADMIN_SETTINGS = "ADMIN_SETTINGS",
  INSTANCES = "INSTANCES",
  INSTANCE = "INSTANCE",
  USERS = "USERS",
  PROFILES = "PROFILES",
  ADMIN_PROFILE = "ADMIN_PROFILE",
  ADMIN_USER_PROFILE = "ADMIN_USER_PROFILE",
  ADMIN_GROUPS = "ADMIN_GROUPS",
  ADMIN_GROUP_PROFILE = "ADMIN_GROUP_PROFILE",
  MODERATION = "MODERATION",
  REPORTS = "REPORTS",
  REPORT = "Report",
  REPORT_LOGS = "Logs",
  CREATE_IDENTITY = "CreateIdentity",
  UPDATE_IDENTITY = "UpdateIdentity",
  IDENTITIES = "IDENTITIES",
  AUTHORIZED_APPS = "AUTHORIZED_APPS",
}

export const settingsRoutes: RouteRecordRaw[] = [
  {
    path: "/settings",
    component: () => import("@/views/SettingsView.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
    redirect: { name: SettingsRouteName.ACCOUNT_SETTINGS },
    name: SettingsRouteName.SETTINGS,
    children: [
      {
        path: "account",
        name: SettingsRouteName.ACCOUNT_SETTINGS,
        redirect: { name: SettingsRouteName.ACCOUNT_SETTINGS_GENERAL },
        meta: {
          requiredAuth: true,
          announcer: { skip: true },
        },
      },
      {
        path: "account/general",
        name: SettingsRouteName.ACCOUNT_SETTINGS_GENERAL,
        component: (): Promise<any> =>
          import("@/views/Settings/AccountSettings.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Account settings") as string,
          },
        },
      },
      {
        path: "preferences",
        name: SettingsRouteName.PREFERENCES,
        component: (): Promise<any> =>
          import("@/views/Settings/PreferencesView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => t("Preferences") as string },
        },
      },
      {
        path: "notifications",
        name: SettingsRouteName.NOTIFICATIONS,
        component: (): Promise<any> =>
          import("@/views/Settings/NotificationsView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Notifications") as string,
          },
        },
      },
      {
        path: "authorized-apps",
        name: SettingsRouteName.AUTHORIZED_APPS,
        component: (): Promise<any> => import("@/views/Settings/AppsView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Apps") as string,
          },
        },
      },
      {
        path: "admin",
        name: SettingsRouteName.ADMIN,
        redirect: { name: SettingsRouteName.ADMIN_DASHBOARD },
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "admin/dashboard",
        name: SettingsRouteName.ADMIN_DASHBOARD,
        component: (): Promise<any> =>
          import("@/views/Admin/DashboardView.vue"),
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Admin dashboard") as string,
          },
        },
      },
      {
        path: "admin/settings",
        name: SettingsRouteName.ADMIN_SETTINGS,
        component: (): Promise<any> => import("@/views/Admin/SettingsView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Admin settings") as string,
          },
        },
      },
      {
        path: "admin/users",
        name: SettingsRouteName.USERS,
        component: (): Promise<any> => import("@/views/Admin/UsersView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => t("Users") as string },
        },
      },
      {
        path: "admin/users/:id",
        name: SettingsRouteName.ADMIN_USER_PROFILE,
        component: (): Promise<any> =>
          import("@/views/Admin/AdminUserProfile.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { skip: true },
        },
      },
      {
        path: "admin/profiles",
        name: SettingsRouteName.PROFILES,
        component: (): Promise<any> => import("@/views/Admin/ProfilesView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => t("Profiles") as string },
        },
      },
      {
        path: "admin/profiles/:id",
        name: SettingsRouteName.ADMIN_PROFILE,
        component: (): Promise<any> => import("@/views/Admin/AdminProfile.vue"),
        props: true,
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "admin/groups",
        name: SettingsRouteName.ADMIN_GROUPS,
        component: (): Promise<any> =>
          import("@/views/Admin/GroupProfiles.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Group profiles") as string,
          },
        },
      },
      {
        path: "admin/groups/:id",
        name: SettingsRouteName.ADMIN_GROUP_PROFILE,
        component: (): Promise<any> =>
          import("@/views/Admin/AdminGroupProfile.vue"),
        props: true,
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "admin/instances",
        name: SettingsRouteName.INSTANCES,
        component: (): Promise<any> =>
          import("@/views/Admin/InstancesView.vue"),
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Instances") as string,
          },
        },
        props: true,
      },
      {
        path: "admin/instances/:domain",
        name: SettingsRouteName.INSTANCE,
        component: (): Promise<any> => import("@/views/Admin/InstanceView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Instance") as string,
          },
        },
      },
      {
        path: "/moderation",
        name: SettingsRouteName.MODERATION,
        redirect: { name: SettingsRouteName.REPORTS },
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "/moderation/reports",
        name: SettingsRouteName.REPORTS,
        component: (): Promise<any> =>
          import("@/views/Moderation/ReportListView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Reports list") as string,
          },
        },
      },
      {
        path: "/moderation/report/:reportId",
        name: SettingsRouteName.REPORT,
        component: (): Promise<any> =>
          import("@/views/Moderation/ReportView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => t("Report") as string },
        },
      },
      {
        path: "/moderation/logs",
        name: SettingsRouteName.REPORT_LOGS,
        component: (): Promise<any> =>
          import("@/views/Moderation/LogsView.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Moderation logs") as string,
          },
        },
      },
      {
        path: "/identity",
        name: SettingsRouteName.IDENTITIES,
        redirect: { name: SettingsRouteName.UPDATE_IDENTITY },
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "/identity/create",
        name: SettingsRouteName.CREATE_IDENTITY,
        component: (): Promise<any> =>
          import("@/views/Account/children/EditIdentity.vue"),
        props: (route: RouteLocationNormalized): Record<string, unknown> => ({
          identityName: route.params.identityName,
          isUpdate: false,
        }),
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => t("Create identity") as string,
          },
        },
      },
      {
        path: "/identity/update/:identityName?",
        name: SettingsRouteName.UPDATE_IDENTITY,
        component: (): Promise<any> =>
          import("@/views/Account/children/EditIdentity.vue"),
        props: (route: RouteLocationNormalized): Record<string, unknown> => ({
          identityName: route.params.identityName,
          isUpdate: true,
        }),
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
    ],
  },
];
