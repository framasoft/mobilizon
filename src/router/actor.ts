import { RouteRecordRaw } from "vue-router";
import { i18n } from "@/utils/i18n";

const { t } = i18n.global;

export enum ActorRouteName {
  GROUP = "Group",
  CREATE_GROUP = "CreateGroup",
  PROFILE = "Profile",
  MY_GROUPS = "MY_GROUPS",
}

export const actorRoutes: RouteRecordRaw[] = [
  {
    path: "/groups/create",
    name: ActorRouteName.CREATE_GROUP,
    component: (): Promise<any> => import("@/views/Group/CreateView.vue"),
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => t("Create group") as string },
    },
  },
  {
    path: "/@:preferredUsername",
    name: ActorRouteName.GROUP,
    component: (): Promise<any> => import("@/views/Group/GroupView.vue"),
    props: true,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/groups/me",
    name: ActorRouteName.MY_GROUPS,
    component: (): Promise<any> => import("@/views/Group/MyGroups.vue"),
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => t("My groups") as string },
    },
  },
];
