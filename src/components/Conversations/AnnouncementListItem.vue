<template>
  <router-link
    class="flex gap-4 w-full items-center px-2 py-4 border-b-stone-200 border-b bg-white dark:bg-transparent my-2 rounded"
    dir="auto"
    :to="{
      name: RouteName.CONVERSATION,
      params: { id: announcement.conversationParticipantId },
    }"
  >
    <div class="overflow-hidden flex-1">
      <div class="flex items-center justify-between">
        <p>
          {{
            t("Sent to {count} participants", otherParticipants.length, {
              count: otherParticipants.length,
            })
          }}
        </p>
        <div class="inline-flex items-center px-1.5">
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
        class="line-clamp-4 my-1"
        dir="auto"
        v-if="!announcement.lastComment?.deletedAt"
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
import { useI18n } from "vue-i18n";
import { useCurrentActorClient } from "@/composition/apollo/actor";

const props = defineProps<{
  announcement: IConversation;
}>();

const announcement = computed(() => props.announcement);

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
  if (announcement.value.lastComment && announcement.value.lastComment.text) {
    element.innerHTML = announcement.value.lastComment.text
      .replace(/<br\s*\/?>/gi, " ")
      .replace(/<p>/gi, " ");
  }
  return element.innerText;
});

const actualDate = computed((): string => {
  if (
    announcement.value.updatedAt === announcement.value.insertedAt &&
    announcement.value.lastComment?.publishedAt
  ) {
    return announcement.value.lastComment.publishedAt;
  }
  return announcement.value.updatedAt;
});

const { currentActor } = useCurrentActorClient();

const otherParticipants = computed(
  () =>
    announcement.value?.participants.filter(
      (participant) => participant.id !== currentActor.value?.id
    ) ?? []
);
</script>
