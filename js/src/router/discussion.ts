import { RouteConfig } from "vue-router";
import CreateDiscussion from "@/views/Discussions/Create.vue";
import DiscussionsList from "@/views/Discussions/DiscussionsList.vue";
import discussion from "@/views/Discussions/Discussion.vue";

export enum DiscussionRouteName {
  DISCUSSION_LIST = "DISCUSSION_LIST",
  CREATE_DISCUSSION = "CREATE_DISCUSSION",
  DISCUSSION = "DISCUSSION",
}

export const discussionRoutes: RouteConfig[] = [
  {
    path: "/@:preferredUsername/discussions",
    name: DiscussionRouteName.DISCUSSION_LIST,
    component: DiscussionsList,
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/discussions/new",
    name: DiscussionRouteName.CREATE_DISCUSSION,
    component: CreateDiscussion,
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/c/:slug/:comment_id?",
    name: DiscussionRouteName.DISCUSSION,
    component: discussion,
    props: true,
    meta: { requiredAuth: false },
  },
];
