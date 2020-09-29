import { RouteConfig } from "vue-router";
import CreateGroup from "@/views/Group/Create.vue";
import Group from "@/views/Group/Group.vue";
import MyGroups from "@/views/Group/MyGroups.vue";

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
    component: CreateGroup,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername",
    name: ActorRouteName.GROUP,
    component: Group,
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/groups/me",
    name: ActorRouteName.MY_GROUPS,
    component: MyGroups,
    meta: { requiredAuth: true },
  },
];
