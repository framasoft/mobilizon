import { RouteConfig } from "vue-router";
import { ImportedComponent } from "vue/types/options";

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
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername",
    name: ActorRouteName.GROUP,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Group" */ "@/views/Group/Group.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/groups/me",
    name: ActorRouteName.MY_GROUPS,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "MyGroups" */ "@/views/Group/MyGroups.vue"),
    meta: { requiredAuth: true },
  },
];
