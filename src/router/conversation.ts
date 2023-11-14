import { RouteRecordRaw } from "vue-router";
import { i18n } from "@/utils/i18n";

const t = i18n.global.t;

export enum ConversationRouteName {
  CONVERSATION_LIST = "DISCUSSION_LIST",
  CONVERSATION = "CONVERSATION",
}

export const conversationRoutes: RouteRecordRaw[] = [
  {
    path: "/conversations",
    name: ConversationRouteName.CONVERSATION_LIST,
    component: (): Promise<any> =>
      import("@/views/Conversations/ConversationListView.vue"),
    props: true,
    meta: {
      requiredAuth: true,
      announcer: {
        message: (): string => t("List of conversations") as string,
      },
    },
  },
  {
    path: "/conversations/:id/:comment_id?",
    name: ConversationRouteName.CONVERSATION,
    component: (): Promise<any> =>
      import("@/views/Conversations/ConversationView.vue"),
    props: true,
    meta: { requiredAuth: true, announcer: { skip: true } },
  },
];
