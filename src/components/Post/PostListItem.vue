<template>
  <router-link
    class="block md:flex bg-white dark:bg-violet-2 dark:text-white dark:hover:text-white rounded-lg shadow-md"
    dir="auto"
    :to="{ name: RouteName.POST, params: { slug: post.slug } }"
  >
    <lazy-image-wrapper
      :picture="post.picture"
      :rounded="true"
      class="object-cover flex-none h-48 md:h-auto md:w-48 rounded-t-lg md:rounded-none md:rounded-l-lg"
    />
    <div class="flex flex-col gap-1 bg-inherit p-2 rounded-lg flex-1">
      <h3
        class="text-xl color-violet-3 line-clamp-3 mb-2 font-bold"
        :lang="post.language"
      >
        {{ post.title }}
      </h3>
      <p class="flex gap-2">
        <Clock />
        <span dir="auto" class="" v-if="publishedAt && isBeforeLastWeek">{{
          formatDateTimeString(
            publishedAt.toString(),
            undefined,
            false,
            "short"
          )
        }}</span>
        <span v-else-if="publishedAt">{{
          formatDistanceToNow(publishedAt, {
            locale: dateFnsLocale,
            addSuffix: true,
          })
        }}</span>
      </p>
      <div v-if="postTags.length > 0" class="flex flex-wrap gap-y-0 gap-x-2">
        <Tag />
        <mbz-tag v-for="tag in postTags" :key="tag.slug">{{
          tag.title
        }}</mbz-tag>
      </div>
      <p class="flex gap-1" v-if="isCurrentActorMember">
        <AccountEdit />
        <i18n-t keypath="Published by {name}">
          <template #name>
            <b class="">{{ displayName(post.author) }}</b>
          </template>
        </i18n-t>
      </p>
      <p
        v-if="post.visibility === PostVisibility.UNLISTED"
        class="flex gap-2 items-center"
      >
        <Link :size="16" />
        {{ t("Accessible only by link") }}
      </p>
      <p
        v-else-if="post.visibility === PostVisibility.PRIVATE"
        class="flex gap-2 items-center"
      >
        <Lock :size="16" />
        {{
          t("Accessible only to members", {
            group: post.attributedTo?.name,
          })
        }}
      </p>
    </div>
  </router-link>
</template>
<script lang="ts" setup>
import { formatDistanceToNow, subWeeks, isBefore, Locale } from "date-fns";
import RouteName from "@/router/name";
import { IPost } from "@/types/post.model";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import { displayName } from "@/types/actor";
import { computed, inject } from "vue";
import { formatDateTimeString } from "@/filters/datetime";
import Tag from "vue-material-design-icons/Tag.vue";
import AccountEdit from "vue-material-design-icons/AccountEdit.vue";
import Clock from "vue-material-design-icons/Clock.vue";
import Lock from "vue-material-design-icons/Lock.vue";
import Link from "vue-material-design-icons/Link.vue";
import MbzTag from "@/components/TagElement.vue";
import { PostVisibility } from "@/types/enums";
import { useI18n } from "vue-i18n";

const props = withDefaults(
  defineProps<{
    post: IPost;
    isCurrentActorMember?: boolean;
  }>(),
  { isCurrentActorMember: false }
);

const { t } = useI18n({ useScope: "global" });
const dateFnsLocale = inject<Locale>("dateFnsLocale");

const postTags = computed(() => (props.post.tags ?? []).slice(0, 3));

const publishedAt = computed((): Date | undefined => {
  const date = props.post.publishAt ?? props.post.insertedAt;
  if (!date) return undefined;
  return new Date(date);
});

const isBeforeLastWeek = computed((): boolean => {
  return (
    publishedAt.value !== undefined &&
    isBefore(publishedAt.value, subWeeks(new Date(), 1))
  );
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

.title-info-wrapper {
  .post-minimalist-title {
    font-size: 18px;
    line-height: 24px;
    font-weight: 700;
    overflow: hidden;
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 3;
  }
}
:deep(.icon) {
  vertical-align: middle;
  // @include margin-right(5px);
}

:deep(.tags) {
  display: inline;

  span.tag {
    max-width: 200px;

    & > span {
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
}
// }
</style>
