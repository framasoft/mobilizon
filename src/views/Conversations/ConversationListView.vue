<template>
  <div class="container mx-auto" v-if="conversations">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.CONVERSATION_LIST,
          text: t('Conversations'),
        },
      ]"
    />
    <o-notification v-if="error" variant="danger">
      {{ error }}
    </o-notification>
    <section>
      <h1>{{ t("Conversations") }}</h1>
      <o-button @click="openNewMessageModal">{{
        t("New private message")
      }}</o-button>
      <div v-if="conversations.elements.length > 0" class="my-2">
        <conversation-list-item
          :conversation="conversation"
          v-for="conversation in conversations.elements"
          :key="conversation.id"
        />
        <o-pagination
          v-show="conversations.total > CONVERSATIONS_PER_PAGE"
          class="conversation-pagination"
          :total="conversations.total"
          v-model:current="page"
          :per-page="CONVERSATIONS_PER_PAGE"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
        >
        </o-pagination>
      </div>
      <empty-content v-else icon="chat">
        {{ t("There's no conversations yet") }}
      </empty-content>
    </section>
  </div>
</template>
<script lang="ts" setup>
import RouteName from "../../router/name";
import { useQuery } from "@vue/apollo-composable";
import { computed, defineAsyncComponent, ref } from "vue";
import { useI18n } from "vue-i18n";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { PROFILE_CONVERSATIONS } from "@/graphql/event";
import ConversationListItem from "../../components/Conversations/ConversationListItem.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { useHead } from "@vueuse/head";
import { IPerson } from "@/types/actor";
import { useProgrammatic } from "@oruga-ui/oruga-next";

const page = useRouteQuery("page", 1, integerTransformer);
const CONVERSATIONS_PER_PAGE = 10;

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("List of conversations")),
});

const error = ref(false);

const { result: conversationsResult } = useQuery<{
  loggedPerson: Pick<IPerson, "conversations">;
}>(PROFILE_CONVERSATIONS, () => ({
  page: page.value,
}));

const conversations = computed(
  () =>
    conversationsResult.value?.loggedPerson.conversations || {
      elements: [],
      total: 0,
    }
);

const { oruga } = useProgrammatic();

const NewConversation = defineAsyncComponent(
  () => import("@/components/Conversations/NewConversation.vue")
);

const openNewMessageModal = () => {
  oruga.modal.open({
    component: NewConversation,
    trapFocus: true,
  });
};
</script>
