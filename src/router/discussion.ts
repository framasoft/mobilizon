import { RouteRecordRaw } from "vue-router";
import { i18n } from "@/utils/i18n";

const t = i18n.global.t;

export enum DiscussionRouteName {
  DISCUSSION_LIST = "DISCUSSION_LIST",
  CREATE_DISCUSSION = "CREATE_DISCUSSION",
  DISCUSSION = "DISCUSSION",
}

export const discussionRoutes: RouteRecordRaw[] = [
  {
    path: "/@:preferredUsername/discussions",
    name: DiscussionRouteName.DISCUSSION_LIST,
    component: (): Promise<any> =>
      import("@/views/Discussions/DiscussionsListView.vue"),
    props: true,
    meta: {
      requiredAuth: true,
      announcer: {
        message: (): string => t("Discussions list") as string,
      },
    },
  },
  {
    path: "/@:preferredUsername/discussions/new",
    name: DiscussionRouteName.CREATE_DISCUSSION,
    component: (): Promise<any> => import("@/views/Discussions/CreateView.vue"),
    props: true,
    meta: {
      requiredAuth: true,
      announcer: {
        message: (): string => t("Create discussion") as string,
      },
    },
  },
  {
    path: "/@:preferredUsername/c/:slug/:comment_id?",
    name: DiscussionRouteName.DISCUSSION,
    component: (): Promise<any> =>
      import("@/views/Discussions/DiscussionView.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
];
