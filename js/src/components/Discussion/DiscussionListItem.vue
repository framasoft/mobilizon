<template>
  <router-link
    class="flex gap-1 w-full items-center p-2 border-b-stone-200 border-b"
    dir="auto"
    :to="{
      name: RouteName.DISCUSSION,
      params: { slug: discussion.slug },
    }"
  >
    <div class="">
      <figure
        class=""
        v-if="
          discussion.lastComment?.actor && discussion.lastComment.actor.avatar
        "
      >
        <img
          class="rounded-xl"
          :src="discussion.lastComment.actor.avatar.url"
          alt=""
          width="32"
          height="32"
        />
      </figure>
      <account-circle :size="32" v-else />
    </div>
    <div class="flex-1">
      <div class="flex items-center">
        <p class="text-violet-3 dark:text-white text-lg font-semibold flex-1">
          {{ discussion.title }}
        </p>
        <span class="" :title="formatDateTimeString(actualDate)">
          {{ distanceToNow }}</span
        >
      </div>
      <div
        class="line-clamp-2"
        dir="auto"
        v-if="!discussion.lastComment?.deletedAt"
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
import { IDiscussion } from "@/types/discussions";
import RouteName from "@/router/name";
import { computed, inject } from "vue";
import { formatDateTimeString } from "@/filters/datetime";
import type { Locale } from "date-fns";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{
  discussion: IDiscussion;
}>();

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
  if (props.discussion.lastComment && props.discussion.lastComment.text) {
    element.innerHTML = props.discussion.lastComment.text
      .replace(/<br\s*\/?>/gi, " ")
      .replace(/<p>/gi, " ");
  }
  return element.innerText;
});

const actualDate = computed((): string => {
  if (
    props.discussion.updatedAt === props.discussion.insertedAt &&
    props.discussion.lastComment?.publishedAt
  ) {
    return props.discussion.lastComment.publishedAt;
  }
  return props.discussion.updatedAt;
});
</script>
