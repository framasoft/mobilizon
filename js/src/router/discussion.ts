import { RouteConfig } from "vue-router";
import { EsModuleComponent } from "vue/types/options";

export enum DiscussionRouteName {
  DISCUSSION_LIST = "DISCUSSION_LIST",
  CREATE_DISCUSSION = "CREATE_DISCUSSION",
  DISCUSSION = "DISCUSSION",
}

export const discussionRoutes: RouteConfig[] = [
  {
    path: "/@:preferredUsername/discussions",
    name: DiscussionRouteName.DISCUSSION_LIST,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "DiscussionsList" */ "@/views/Discussions/DiscussionsList.vue"
      ),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/discussions/new",
    name: DiscussionRouteName.CREATE_DISCUSSION,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "CreateDiscussion" */ "@/views/Discussions/Create.vue"
      ),
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/c/:slug/:comment_id?",
    name: DiscussionRouteName.DISCUSSION,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "Discussion" */ "@/views/Discussions/Discussion.vue"
      ),
    props: true,
    meta: { requiredAuth: true },
  },
];
