<template>
  <form @submit="sendForm" class="flex flex-col">
    <ActorAutoComplete v-model="actorMentions" />
    <Editor
      v-model="text"
      mode="basic"
      :aria-label="t('Message body')"
      v-if="currentActor"
      :currentActor="currentActor"
      :placeholder="t('Write a new message')"
    />
    <footer class="flex gap-2 py-3 mx-2 justify-end">
      <o-button :disabled="!canSend" nativeType="submit">{{
        t("Send")
      }}</o-button>
    </footer>
  </form>
</template>

<script lang="ts" setup>
import { IActor, IPerson, usernameWithDomain } from "@/types/actor";
import { computed, defineAsyncComponent, provide, ref } from "vue";
import { useI18n } from "vue-i18n";
import ActorAutoComplete from "../../components/Account/ActorAutoComplete.vue";
import {
  DefaultApolloClient,
  provideApolloClient,
  useMutation,
} from "@vue/apollo-composable";
import { apolloClient } from "@/vue-apollo";
import { PROFILE_CONVERSATIONS } from "@/graphql/event";
import { POST_PRIVATE_MESSAGE_MUTATION } from "@/graphql/conversations";
import { IConversation } from "@/types/conversation";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useRouter } from "vue-router";
import RouteName from "@/router/name";

const props = withDefaults(
  defineProps<{
    mentions?: IActor[];
  }>(),
  { mentions: () => [] }
);

provide(DefaultApolloClient, apolloClient);

const router = useRouter();

const emit = defineEmits(["close"]);

const actorMentions = ref(props.mentions);

const textMentions = computed(() =>
  (props.mentions ?? []).map((actor) => usernameWithDomain(actor)).join(" ")
);

const { t } = useI18n({ useScope: "global" });

const text = ref(textMentions.value);

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);

const { currentActor } = provideApolloClient(apolloClient)(() => {
  return useCurrentActorClient();
});

const canSend = computed(() => {
  return actorMentions.value.length > 0 || /@.+/.test(text.value);
});

const { mutate: postPrivateMessageMutate } = provideApolloClient(apolloClient)(
  () =>
    useMutation<
      {
        postPrivateMessage: IConversation;
      },
      {
        text: string;
        actorId: string;
        language?: string;
        mentions?: string[];
        attributedToId?: string;
      }
    >(POST_PRIVATE_MESSAGE_MUTATION, {
      update(cache, result) {
        if (!result.data?.postPrivateMessage) return;
        const cachedData = cache.readQuery<{
          loggedPerson: Pick<IPerson, "conversations" | "id">;
        }>({
          query: PROFILE_CONVERSATIONS,
          variables: {
            page: 1,
          },
        });
        if (!cachedData) return;
        cache.writeQuery({
          query: PROFILE_CONVERSATIONS,
          variables: {
            page: 1,
          },
          data: {
            loggedPerson: {
              ...cachedData?.loggedPerson,
              conversations: {
                ...cachedData.loggedPerson.conversations,
                total: (cachedData.loggedPerson.conversations?.total ?? 0) + 1,
                elements: [
                  ...(cachedData.loggedPerson.conversations?.elements ?? []),
                  result.data.postPrivateMessage,
                ],
              },
            },
          },
        });
      },
    })
);

const sendForm = async (e: Event) => {
  e.preventDefault();
  console.debug("Sending new private message");
  if (!currentActor.value?.id) return;
  const result = await postPrivateMessageMutate({
    actorId: currentActor.value.id,
    text: text.value,
    mentions: actorMentions.value.map((actor) => usernameWithDomain(actor)),
  });
  if (!result?.data?.postPrivateMessage.conversationParticipantId) return;
  router.push({
    name: RouteName.CONVERSATION,
    params: { id: result?.data?.postPrivateMessage.conversationParticipantId },
  });
  emit("close");
};
</script>
