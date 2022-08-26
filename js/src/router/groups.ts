import { RouteLocationNormalized, RouteRecordRaw } from "vue-router";

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
  GROUP_FOLLOW = "GROUP_FOLLOW",
  TIMELINE = "TIMELINE",
}

const resourceFolder = (): Promise<any> =>
  import("@/views/Resources/ResourceFolder.vue");
const groupEvents = (): Promise<any> => import("@/views/Event/GroupEvents.vue");

export const groupsRoutes: RouteRecordRaw[] = [
  {
    path: "/@:preferredUsername/todo-lists",
    name: GroupsRouteName.TODO_LISTS,
    component: (): Promise<any> => import("@/views/Todos/TodoLists.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/todo-lists/:id",
    name: GroupsRouteName.TODO_LIST,
    component: (): Promise<any> => import("@/views/Todos/TodoList.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/todo/:todoId",
    name: GroupsRouteName.TODO,
    component: (): Promise<any> => import("@/views/Todos/TodoView.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/resources",
    name: GroupsRouteName.RESOURCE_FOLDER_ROOT,
    component: resourceFolder,
    props: (to) => ({
      path: "/",
      preferredUsername: to.params.preferredUsername,
    }),
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/resources/:path+",
    name: GroupsRouteName.RESOURCE_FOLDER,
    component: resourceFolder,
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/settings",
    component: (): Promise<any> => import("@/views/Group/SettingsView.vue"),
    props: true,
    meta: { requiredAuth: true },
    redirect: { name: GroupsRouteName.GROUP_PUBLIC_SETTINGS },
    name: GroupsRouteName.GROUP_SETTINGS,
    children: [
      {
        path: "public",
        name: GroupsRouteName.GROUP_PUBLIC_SETTINGS,
        props: true,
        component: (): Promise<any> =>
          import("../views/Group/GroupSettings.vue"),
        meta: { announcer: { skip: true } },
      },
      {
        path: "members",
        name: GroupsRouteName.GROUP_MEMBERS_SETTINGS,
        component: (): Promise<any> =>
          import("../views/Group/GroupMembers.vue"),
        props: true,
        meta: { announcer: { skip: true } },
      },
      {
        path: "followers",
        name: GroupsRouteName.GROUP_FOLLOWERS_SETTINGS,
        component: (): Promise<any> =>
          import("../views/Group/GroupFollowers.vue"),
        props: true,
        meta: { announcer: { skip: true } },
      },
    ],
  },
  {
    path: "/@:preferredUsername/p/new",
    component: (): Promise<any> => import("@/views/Posts/EditView.vue"),
    props: true,
    name: GroupsRouteName.POST_CREATE,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/p/:slug/edit",
    component: (): Promise<any> => import("@/views/Posts/EditView.vue"),
    props: (route: RouteLocationNormalized): Record<string, unknown> => ({
      ...route.params,
      ...{ isUpdate: true },
    }),
    name: GroupsRouteName.POST_EDIT,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
  {
    path: "/p/:slug",
    component: (): Promise<any> => import("@/views/Posts/PostView.vue"),
    props: true,
    name: GroupsRouteName.POST,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/p",
    component: (): Promise<any> => import("@/views/Posts/ListView.vue"),
    props: true,
    name: GroupsRouteName.POSTS,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/events",
    component: groupEvents,
    props: true,
    name: GroupsRouteName.GROUP_EVENTS,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/join",
    component: (): Promise<any> =>
      import("@/components/Group/JoinGroupWithAccount.vue"),
    props: true,
    name: GroupsRouteName.GROUP_JOIN,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/follow",
    component: (): Promise<any> =>
      import("@/components/Group/JoinGroupWithAccount.vue"),
    props: true,
    name: GroupsRouteName.GROUP_FOLLOW,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/@:preferredUsername/timeline",
    name: GroupsRouteName.TIMELINE,
    component: (): Promise<any> => import("@/views/Group/TimelineView.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
];
