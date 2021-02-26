import { RouteConfig, Route } from "vue-router";
import { EsModuleComponent } from "vue/types/options";

export enum GroupsRouteName {
  TODO_LISTS = "TODO_LISTS",
  TODO_LIST = "TODO_LIST",
  TODO = "TODO",
  GROUP_SETTINGS = "GROUP_SETTINGS",
  GROUP_PUBLIC_SETTINGS = "GROUP_PUBLIC_SETTINGS",
  GROUP_MEMBERS_SETTINGS = "GROUP_MEMBERS_SETTINGS",
  GROUP_FOLLOWERS_SETTINGS = "GROUP_FOLLOWERS_SETTINGS",
  RESOURCES = "RESOURCES",
  RESOURCE_FOLDER_ROOT = "RESOURCE_FOLDER_ROOT",
  RESOURCE_FOLDER = "RESOURCE_FOLDER",
  POST_CREATE = "POST_CREATE",
  POST_EDIT = "POST_EDIT",
  POST = "POST",
  POSTS = "POSTS",
  GROUP_EVENTS = "GROUP_EVENTS",
  GROUP_JOIN = "GROUP_JOIN",
  TIMELINE = "TIMELINE",
}

const resourceFolder = (): Promise<EsModuleComponent> =>
  import("@/views/Resources/ResourceFolder.vue");
const groupEvents = (): Promise<EsModuleComponent> =>
  import(/* webpackChunkName: "groupEvents" */ "@/views/Event/GroupEvents.vue");

export const groupsRoutes: RouteConfig[] = [
  {
    path: "/@:preferredUsername/todo-lists",
    name: GroupsRouteName.TODO_LISTS,
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Todos/TodoLists.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/todo-lists/:id",
    name: GroupsRouteName.TODO_LIST,
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Todos/TodoList.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/todo/:todoId",
    name: GroupsRouteName.TODO,
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Todos/Todo.vue"),
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
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Group/Settings.vue"),
    props: true,
    meta: { requiredAuth: true },
    redirect: { name: GroupsRouteName.GROUP_PUBLIC_SETTINGS },
    name: GroupsRouteName.GROUP_SETTINGS,
    children: [
      {
        path: "public",
        name: GroupsRouteName.GROUP_PUBLIC_SETTINGS,
        component: (): Promise<EsModuleComponent> =>
          import("../views/Group/GroupSettings.vue"),
      },
      {
        path: "members",
        name: GroupsRouteName.GROUP_MEMBERS_SETTINGS,
        component: (): Promise<EsModuleComponent> =>
          import("../views/Group/GroupMembers.vue"),
        props: true,
      },
      {
        path: "followers",
        name: GroupsRouteName.GROUP_FOLLOWERS_SETTINGS,
        component: (): Promise<EsModuleComponent> =>
          import("../views/Group/GroupFollowers.vue"),
        props: true,
      },
    ],
  },
  {
    path: "/@:preferredUsername/p/new",
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Posts/Edit.vue"),
    props: true,
    name: GroupsRouteName.POST_CREATE,
    meta: { requiredAuth: true },
  },
  {
    path: "/p/:slug/edit",
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Posts/Edit.vue"),
    props: (route: Route): Record<string, unknown> => ({
      ...route.params,
      ...{ isUpdate: true },
    }),
    name: GroupsRouteName.POST_EDIT,
    meta: { requiredAuth: true },
  },
  {
    path: "/p/:slug",
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Posts/Post.vue"),
    props: true,
    name: GroupsRouteName.POST,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/p",
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Posts/List.vue"),
    props: true,
    name: GroupsRouteName.POSTS,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/events",
    component: groupEvents,
    props: true,
    name: GroupsRouteName.GROUP_EVENTS,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/join",
    component: (): Promise<EsModuleComponent> =>
      import("@/components/Group/JoinGroupWithAccount.vue"),
    props: true,
    name: GroupsRouteName.GROUP_JOIN,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/timeline",
    name: GroupsRouteName.TIMELINE,
    component: (): Promise<EsModuleComponent> =>
      import("@/views/Group/Timeline.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
];
