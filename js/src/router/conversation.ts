import { RouteConfig } from "vue-router";
import CreateConversation from "@/views/Conversations/Create.vue";
import ConversationsList from "@/views/Conversations/ConversationsList.vue";
import Conversation from "@/views/Conversations/Conversation.vue";

export enum ConversationRouteName {
  CONVERSATION_LIST = "CONVERSATION_LIST",
  CREATE_CONVERSATION = "CREATE_CONVERSATION",
  CONVERSATION = "CONVERSATION",
}

export const conversationRoutes: RouteConfig[] = [
  {
    path: "/@:preferredUsername/conversations",
    name: ConversationRouteName.CONVERSATION_LIST,
    component: ConversationsList,
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/@:preferredUsername/conversations/new",
    name: ConversationRouteName.CREATE_CONVERSATION,
    component: CreateConversation,
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: "/@:preferredUsername/:slug/:id/:comment_id?",
    name: ConversationRouteName.CONVERSATION,
    component: Conversation,
    props: true,
    meta: { requiredAuth: false },
  },
];
