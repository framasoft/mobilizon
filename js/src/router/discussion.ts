import { RouteConfig } from "vue-router";

export enum DiscussionRouteName {
  DISCUSSION_LIST = "DISCUSSION_LIST",
  CREATE_DISCUSSION = "CREATE_DISCUSSION",
  DISCUSSION = "DISCUSSION",
}

export const discussionRoutes: RouteConfig[] = [
  {
    path: "/@:preferredUsername/discussions",
    name: DiscussionRouteName.DISCUSSION_LIST,
    component: () =>
      import(/* webpackChunkName: "DiscussionsList" */ "@/views/Discussions/DiscussionsList.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/discussions/new",
    name: DiscussionRouteName.CREATE_DISCUSSION,
    component: () =>
      import(/* webpackChunkName: "CreateDiscussion" */ "@/views/Discussions/Create.vue"),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/c/:slug/:comment_id?",
    name: DiscussionRouteName.DISCUSSION,
    component: () =>
      import(/* webpackChunkName: "Discussion" */ "@/views/Discussions/Discussion.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
];
