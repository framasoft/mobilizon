import { Route, RouteConfig } from "vue-router";
import { ImportedComponent } from "vue/types/options";
import { i18n } from "@/utils/i18n";

export enum SettingsRouteName {
  SETTINGS = "SETTINGS",
  ACCOUNT_SETTINGS = "ACCOUNT_SETTINGS",
  ACCOUNT_SETTINGS_GENERAL = "ACCOUNT_SETTINGS_GENERAL",
  PREFERENCES = "PREFERENCES",
  NOTIFICATIONS = "NOTIFICATIONS",
  ADMIN = "ADMIN",
  ADMIN_DASHBOARD = "ADMIN_DASHBOARD",
  ADMIN_SETTINGS = "ADMIN_SETTINGS",
  RELAYS = "Relays",
  RELAY_FOLLOWINGS = "Followings",
  RELAY_FOLLOWERS = "Followers",
  USERS = "USERS",
  PROFILES = "PROFILES",
  ADMIN_PROFILE = "ADMIN_PROFILE",
  ADMIN_USER_PROFILE = "ADMIN_USER_PROFILE",
  ADMIN_GROUPS = "ADMIN_GROUPS",
  ADMIN_GROUP_PROFILE = "ADMIN_GROUP_PROFILE",
  MODERATION = "MODERATION",
  REPORTS = "Reports",
  REPORT = "Report",
  REPORT_LOGS = "Logs",
  CREATE_IDENTITY = "CreateIdentity",
  UPDATE_IDENTITY = "UpdateIdentity",
  IDENTITIES = "IDENTITIES",
}

export const settingsRoutes: RouteConfig[] = [
  {
    path: "/settings",
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Settings" */ "@/views/Settings.vue"),
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
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "AccountSettings" */ "@/views/Settings/AccountSettings.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Account settings") as string,
          },
        },
      },
      {
        path: "preferences",
        name: SettingsRouteName.PREFERENCES,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "Preferences" */ "@/views/Settings/Preferences.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => i18n.t("Preferences") as string },
        },
      },
      {
        path: "notifications",
        name: SettingsRouteName.NOTIFICATIONS,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "Notifications" */ "@/views/Settings/Notifications.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Notifications") as string,
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
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "Dashboard" */ "@/views/Admin/Dashboard.vue"
          ),
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Admin dashboard") as string,
          },
        },
      },
      {
        path: "admin/settings",
        name: SettingsRouteName.ADMIN_SETTINGS,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "AdminSettings" */ "@/views/Admin/Settings.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Admin settings") as string,
          },
        },
      },
      {
        path: "admin/users",
        name: SettingsRouteName.USERS,
        component: (): Promise<ImportedComponent> =>
          import(/* webpackChunkName: "Users" */ "@/views/Admin/Users.vue"),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => i18n.t("Users") as string },
        },
      },
      {
        path: "admin/users/:id",
        name: SettingsRouteName.ADMIN_USER_PROFILE,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "AdminUserProfile" */ "@/views/Admin/AdminUserProfile.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { skip: true },
        },
      },
      {
        path: "admin/profiles",
        name: SettingsRouteName.PROFILES,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "AdminProfiles" */ "@/views/Admin/Profiles.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => i18n.t("Profiles") as string },
        },
      },
      {
        path: "admin/profiles/:id",
        name: SettingsRouteName.ADMIN_PROFILE,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "AdminProfile" */ "@/views/Admin/AdminProfile.vue"
          ),
        props: true,
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "admin/groups",
        name: SettingsRouteName.ADMIN_GROUPS,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "GroupProfiles" */ "@/views/Admin/GroupProfiles.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Group profiles") as string,
          },
        },
      },
      {
        path: "admin/groups/:id",
        name: SettingsRouteName.ADMIN_GROUP_PROFILE,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "AdminGroupProfile" */ "@/views/Admin/AdminGroupProfile.vue"
          ),
        props: true,
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "admin/relays",
        name: SettingsRouteName.RELAYS,
        redirect: { name: SettingsRouteName.RELAY_FOLLOWINGS },
        component: (): Promise<ImportedComponent> =>
          import(/* webpackChunkName: "Follows" */ "@/views/Admin/Follows.vue"),
        meta: { requiredAuth: true, announcer: { skip: true } },
        children: [
          {
            path: "followings",
            name: SettingsRouteName.RELAY_FOLLOWINGS,
            component: (): Promise<ImportedComponent> =>
              import(
                /* webpackChunkName: "Followings" */ "@/components/Admin/Followings.vue"
              ),
            meta: {
              requiredAuth: true,
              announcer: {
                message: (): string => i18n.t("Followings") as string,
              },
            },
          },
          {
            path: "followers",
            name: SettingsRouteName.RELAY_FOLLOWERS,
            component: (): Promise<ImportedComponent> =>
              import(
                /* webpackChunkName: "Followers" */ "@/components/Admin/Followers.vue"
              ),
            meta: {
              requiredAuth: true,
              announcer: {
                message: (): string => i18n.t("Followers") as string,
              },
            },
          },
        ],
        props: true,
      },
      {
        path: "/moderation",
        name: SettingsRouteName.MODERATION,
        redirect: { name: SettingsRouteName.REPORTS },
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
      {
        path: "/moderation/reports/:filter?",
        name: SettingsRouteName.REPORTS,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "ReportList" */ "@/views/Moderation/ReportList.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Reports list") as string,
          },
        },
      },
      {
        path: "/moderation/report/:reportId",
        name: SettingsRouteName.REPORT,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "Report" */ "@/views/Moderation/Report.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: { message: (): string => i18n.t("Report") as string },
        },
      },
      {
        path: "/moderation/logs",
        name: SettingsRouteName.REPORT_LOGS,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "ModerationLogs" */ "@/views/Moderation/Logs.vue"
          ),
        props: true,
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Moderation logs") as string,
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
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "EditIdentity" */ "@/views/Account/children/EditIdentity.vue"
          ),
        props: (route: Route): Record<string, unknown> => ({
          identityName: route.params.identityName,
          isUpdate: false,
        }),
        meta: {
          requiredAuth: true,
          announcer: {
            message: (): string => i18n.t("Create identity") as string,
          },
        },
      },
      {
        path: "/identity/update/:identityName?",
        name: SettingsRouteName.UPDATE_IDENTITY,
        component: (): Promise<ImportedComponent> =>
          import(
            /* webpackChunkName: "EditIdentity" */ "@/views/Account/children/EditIdentity.vue"
          ),
        props: (route: Route): Record<string, unknown> => ({
          identityName: route.params.identityName,
          isUpdate: true,
        }),
        meta: { requiredAuth: true, announcer: { skip: true } },
      },
    ],
  },
];
