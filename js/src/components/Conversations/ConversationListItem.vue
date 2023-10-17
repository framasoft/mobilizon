<template>
  <router-link
    class="flex gap-2 w-full items-center px-2 py-4 border-b-stone-200 border-b bg-white dark:bg-transparent"
    dir="auto"
    :to="{
      name: RouteName.CONVERSATION,
      params: { id: conversation.conversationParticipantId },
    }"
  >
    <div class="relative">
      <figure
        class="w-12 h-12"
        v-if="
          conversation.lastComment?.actor &&
          conversation.lastComment.actor.avatar
        "
      >
        <img
          class="rounded-full"
          :src="conversation.lastComment.actor.avatar.url"
          alt=""
          width="48"
          height="48"
        />
      </figure>
      <account-circle :size="48" v-else />
      <div class="flex absolute -bottom-2 left-6">
        <template
          v-for="extraParticipant in nonLastCommenterParticipants.slice(0, 2)"
          :key="extraParticipant.id"
        >
          <figure class="w-6 h-6 -mr-3">
            <img
              v-if="extraParticipant && extraParticipant.avatar"
              class="rounded-full h-6"
              :src="extraParticipant.avatar.url"
              alt=""
              width="24"
              height="24"
            />
            <account-circle :size="24" v-else />
          </figure>
        </template>
      </div>
    </div>
    <div class="overflow-hidden flex-1">
      <div class="flex items-center justify-between">
        <i18n-t
          keypath="With {participants}"
          tag="p"
          class="truncate flex-1"
          v-if="formattedListOfParticipants"
        >
          <template #participants>
            <span v-html="formattedListOfParticipants" />
          </template>
        </i18n-t>
        <p v-else>{{ t("With unknown participants") }}</p>
        <div class="inline-flex items-center px-1.5">
          <span
            v-if="conversation.unread"
            class="bg-primary rounded-full inline-block h-2.5 w-2.5 mx-2"
          >
          </span>
          <time
            class="whitespace-nowrap"
            :datetime="actualDate.toString()"
            :title="formatDateTimeString(actualDate)"
          >
            {{ distanceToNow }}</time
          >
        </div>
      </div>
      <div
        class="line-clamp-2 my-1"
        dir="auto"
        v-if="!conversation.lastComment?.deletedAt"
      >
        {{ htmlTextEllipsis }}
      </div>
      <div v-else class="">
        {{ t("[This comment has been deleted]") }}
      </div>
    </div>
  </router-link>
</template>
<script lang="ts" setup>
import { formatDistanceToNowStrict } from "date-fns";
import { IConversation } from "../../types/conversation";
import RouteName from "../../router/name";
import { computed, inject } from "vue";
import { formatDateTimeString } from "../../filters/datetime";
import type { Locale } from "date-fns";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useI18n } from "vue-i18n";
import { formatList } from "@/utils/i18n";
import { displayName } from "@/types/actor";
import { useCurrentActorClient } from "@/composition/apollo/actor";

const props = defineProps<{
  conversation: IConversation;
}>();

const conversation = computed(() => props.conversation);

const dateFnsLocale = inject<Locale>("dateFnsLocale");
const { t } = useI18n({ useScope: "global" });

const distanceToNow = computed(() => {
  return (
    formatDistanceToNowStrict(new Date(actualDate.value), {
      locale: dateFnsLocale,
    }) ?? t("Right now")
  );
});

const htmlTextEllipsis = computed((): string => {
  const element = document.createElement("div");
  if (conversation.value.lastComment && conversation.value.lastComment.text) {
    element.innerHTML = conversation.value.lastComment.text
      .replace(/<br\s*\/?>/gi, " ")
      .replace(/<p>/gi, " ");
  }
  return element.innerText;
});

const actualDate = computed((): string => {
  if (
    conversation.value.updatedAt === conversation.value.insertedAt &&
    conversation.value.lastComment?.publishedAt
  ) {
    return conversation.value.lastComment.publishedAt;
  }
  return conversation.value.updatedAt;
});

const formattedListOfParticipants = computed(() => {
  return formatList(
    otherParticipants.value.map(
      (participant) => `<b>${displayName(participant)}</b>`
    )
  );
});

const { currentActor } = useCurrentActorClient();

const otherParticipants = computed(
  () =>
    conversation.value?.participants.filter(
      (participant) => participant.id !== currentActor.value?.id
    ) ?? []
);

const nonLastCommenterParticipants = computed(() =>
  otherParticipants.value.filter(
    (participant) =>
      participant.id !== conversation.value.lastComment?.actor?.id
  )
);
</script>
