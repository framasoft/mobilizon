import { RouteConfig } from "vue-router";

export enum GroupsRouteName {
  TODO_LISTS = "TODO_LISTS",
  TODO_LIST = "TODO_LIST",
  TODO = "TODO",
  GROUP_SETTINGS = "GROUP_SETTINGS",
  GROUP_PUBLIC_SETTINGS = "GROUP_PUBLIC_SETTINGS",
  GROUP_MEMBERS_SETTINGS = "GROUP_MEMBERS_SETTINGS",
  RESOURCES = "RESOURCES",
  RESOURCE_FOLDER_ROOT = "RESOURCE_FOLDER_ROOT",
  RESOURCE_FOLDER = "RESOURCE_FOLDER",
}

const resourceFolder = () => import("@/views/Resources/ResourceFolder.vue");

export const groupsRoutes: RouteConfig[] = [
  {
    path: "/@:preferredUsername/todo-lists",
    name: GroupsRouteName.TODO_LISTS,
    component: () => import("@/views/Todos/TodoLists.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/todo-lists/:id",
    name: GroupsRouteName.TODO_LIST,
    component: () => import("@/views/Todos/TodoList.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/todo/:todoId",
    name: GroupsRouteName.TODO,
    component: () => import("@/views/Todos/Todo.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/resources",
    name: GroupsRouteName.RESOURCE_FOLDER_ROOT,
    component: resourceFolder,
    props: { path: "/" },
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/resources/:path+",
    name: GroupsRouteName.RESOURCE_FOLDER,
    component: resourceFolder,
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/settings",
    component: () => import("@/views/Group/Settings.vue"),
    props: true,
    meta: { requiredAuth: true },
    redirect: { name: GroupsRouteName.GROUP_PUBLIC_SETTINGS },
    name: GroupsRouteName.GROUP_SETTINGS,
    children: [
      {
        path: "public",
        name: GroupsRouteName.GROUP_PUBLIC_SETTINGS,
      },
      {
        path: "members",
        name: GroupsRouteName.GROUP_MEMBERS_SETTINGS,
        component: () => import("../views/Group/GroupMembers.vue"),
        props: true,
      },
    ],
  },
];
