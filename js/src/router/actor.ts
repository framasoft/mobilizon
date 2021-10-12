import { RouteConfig } from "vue-router";
import { ImportedComponent } from "vue/types/options";
import { i18n } from "@/utils/i18n";

export enum ActorRouteName {
  GROUP = "Group",
  CREATE_GROUP = "CreateGroup",
  PROFILE = "Profile",
  MY_GROUPS = "MY_GROUPS",
}

export const actorRoutes: RouteConfig[] = [
  {
    path: "/groups/create",
    name: ActorRouteName.CREATE_GROUP,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "CreateGroup" */ "@/views/Group/Create.vue"),
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => i18n.t("Create group") as string },
    },
  },
  {
    path: "/@:preferredUsername",
    name: ActorRouteName.GROUP,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Group" */ "@/views/Group/Group.vue"),
    props: true,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/groups/me",
    name: ActorRouteName.MY_GROUPS,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "MyGroups" */ "@/views/Group/MyGroups.vue"),
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => i18n.t("My groups") as string },
    },
  },
];
