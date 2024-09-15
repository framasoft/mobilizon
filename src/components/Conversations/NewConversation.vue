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
    <o-notification
      class="my-2"
      variant="danger"
      :closable="false"
      v-for="error in errors"
      :key="error"
    >
      {{ error }}
    </o-notification>
    <footer class="flex gap-2 py-3 mx-2 justify-end">
      <o-button :disabled="!canSend" nativeType="submit">{{
        t("Send")
      }}</o-button>
    </footer>
  </form>
</template>

<script lang="ts" setup>
import { IActor, IGroup, IPerson, usernameWithDomain } from "@/types/actor";
import { computed, defineAsyncComponent, provide, ref } from "vue";
import { useI18n } from "vue-i18n";
import ActorAutoComplete from "../../components/Account/ActorAutoComplete.vue";
import {
  DefaultApolloClient,
  provideApolloClient,
  useLazyQuery,
  useMutation,
} from "@vue/apollo-composable";
import { apolloClient } from "@/vue-apollo";
import { PROFILE_CONVERSATIONS } from "@/graphql/event";
import { POST_PRIVATE_MESSAGE_MUTATION } from "@/graphql/conversations";
import { IConversation } from "@/types/conversation";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useRouter } from "vue-router";
import RouteName from "@/router/name";
import { FETCH_PERSON } from "@/graphql/actor";
import { FETCH_GROUP_PUBLIC } from "@/graphql/group";

const props = withDefaults(
  defineProps<{
    personMentions?: string[];
    groupMentions?: string[];
  }>(),
  { personMentions: () => [], groupMentions: () => [] }
);

provide(DefaultApolloClient, apolloClient);

const router = useRouter();

const emit = defineEmits(["close"]);

const errors = ref<string[]>([]);

const textPersonMentions = computed(() => props.personMentions);
const textGroupMentions = computed(() => props.groupMentions);
const actorMentions = ref<IActor[]>([]);

const { load: fetchPerson } = provideApolloClient(apolloClient)(() =>
  useLazyQuery<{ fetchPerson: IPerson }, { username: string }>(FETCH_PERSON)
);
const { load: fetchGroup } = provideApolloClient(apolloClient)(() =>
  useLazyQuery<{ group: IGroup }, { name: string }>(FETCH_GROUP_PUBLIC)
);
textPersonMentions.value.forEach(async (textPersonMention) => {
  const result = await fetchPerson(FETCH_PERSON, {
    username: textPersonMention,
  });
  if (!result) return;
  actorMentions.value.push(result.fetchPerson);
});
textGroupMentions.value.forEach(async (textGroupMention) => {
  const result = await fetchGroup(FETCH_GROUP_PUBLIC, {
    name: textGroupMention,
  });
  if (!result) return;
  actorMentions.value.push(result.group);
});

const { t } = useI18n({ useScope: "global" });

const text = ref("");

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);

const { currentActor } = provideApolloClient(apolloClient)(() => {
  return useCurrentActorClient();
});

const canSend = computed(() => {
  return actorMentions.value.length > 0 || /@.+/.test(text.value);
});

const { mutate: postPrivateMessageMutate, onError: onPrivateMessageError } =
  provideApolloClient(apolloClient)(() =>
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

onPrivateMessageError((err) => {
  err.graphQLErrors.forEach((error) => {
    errors.value.push(error.message);
  });
});

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
