<template>
  <form @submit="sendForm">
    <h2>{{ t("New announcement") }}</h2>
    <p>
      {{
        t(
          "This announcement will be send to all participants with the statuses selected below. They will not be allowed to reply to your announcement, but they can create a new conversation with you."
        )
      }}
    </p>
    <o-field class="mt-2 mb-4">
      <o-checkbox
        v-model="selectedRoles"
        :native-value="ParticipantRole.PARTICIPANT"
        :label="t('Participant')"
      />
      <o-checkbox
        v-model="selectedRoles"
        :native-value="ParticipantRole.NOT_APPROVED"
        :label="t('Not approved')"
      />
      <o-checkbox
        v-model="selectedRoles"
        :native-value="ParticipantRole.REJECTED"
        :label="t('Rejected')"
      />
    </o-field>
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
      :closable="true"
      v-for="error in errors"
      :key="error"
    >
      {{ error }}
    </o-notification>
    <o-button
      class="mt-3"
      nativeType="submit"
      :disabled="selectedRoles.length == 0"
      >{{ t("Send") }}</o-button
    >
  </form>
</template>

<script lang="ts" setup>
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { SEND_EVENT_PRIVATE_MESSAGE_MUTATION } from "@/graphql/conversations";
import { EVENT_CONVERSATIONS } from "@/graphql/event";
import { IConversation } from "@/types/conversation";
import { ParticipantRole } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { useMutation } from "@vue/apollo-composable";
import { computed, defineAsyncComponent, ref } from "vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  event: IEvent;
}>();

const event = computed(() => props.event);

const text = ref("");

const errors = ref<string[]>([]);

const selectedRoles = ref<ParticipantRole[]>([ParticipantRole.PARTICIPANT]);

const {
  mutate: eventPrivateMessageMutate,
  onDone: onEventPrivateMessageMutated,
  onError: onEventPrivateMessageError,
} = useMutation<
  {
    sendEventPrivateMessage: IConversation;
  },
  {
    text: string;
    actorId: string;
    eventId: string;
    roles?: ParticipantRole[];
    language?: string;
  }
>(SEND_EVENT_PRIVATE_MESSAGE_MUTATION, {
  update(cache, result) {
    if (!result.data?.sendEventPrivateMessage) return;
    const cachedData = cache.readQuery<{
      event: Pick<IEvent, "conversations" | "id" | "uuid">;
    }>({
      query: EVENT_CONVERSATIONS,
      variables: {
        uuid: event.value.uuid,
        page: 1,
      },
    });
    if (!cachedData) return;
    cache.writeQuery({
      query: EVENT_CONVERSATIONS,
      variables: {
        uuid: event.value.uuid,
        page: 1,
      },
      data: {
        event: {
          ...cachedData?.event,
          conversations: {
            ...cachedData.event.conversations,
            total: cachedData.event.conversations.total + 1,
            elements: [
              ...cachedData.event.conversations.elements,
              result.data.sendEventPrivateMessage,
            ],
          },
        },
      },
    });
  },
});

const { currentActor } = useCurrentActorClient();

const sendForm = (e: Event) => {
  e.preventDefault();
  console.debug("Sending new private message");
  if (!currentActor.value?.id || !event.value.id) return;
  errors.value = [];
  eventPrivateMessageMutate({
    text: text.value,
    actorId:
      event.value?.attributedTo?.id ??
      event.value.organizerActor?.id ??
      currentActor.value?.id,
    eventId: event.value.id,
    roles: selectedRoles.value,
  });
};

onEventPrivateMessageMutated(() => {
  text.value = "";
});

onEventPrivateMessageError((err) => {
  err.graphQLErrors.forEach((error) => {
    const message = Array.isArray(error.message)
      ? error.message
      : [error.message];
    errors.value.push(...message);
  });
});

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);
</script>
