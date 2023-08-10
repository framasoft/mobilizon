<template>
  <router-link
    :to="to"
    class="mbz-card flex flex-col items-center dark:border-gray-700 shadow-md md:flex-col snap-center shrink-0 first:pl-8 w-[18rem] dark:bg-mbz-purple"
  >
    <div class="relative w-full group">
      <img
        v-if="picture"
        class="object-cover h-40 w-full rounded-t-lg"
        :src="picture.url"
        width="350"
        alt=""
        loading="lazy"
      />
      <div class="absolute top-0 left-0 h-full w-full">
        <div
          class="custom-overlay opacity-0 invisible group-hover:opacity-100 group-hover:visible absolute left-0 h-full w-full transition-opacity"
        />
        <div
          class="opacity-0 invisible group-hover:opacity-100 group-hover:visible absolute left-0 h-full w-full"
        >
          <p class="absolute text-sm text-white left-1 bottom-1.5 px-1">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="inline h-5 w-5 pr-1"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span
              @click="(e) => e.stopPropagation()"
              class="align-bottom"
              v-html="
                $t('Photo by {author} on {source}', {
                  author: imageAuthor,
                  source: imageSource,
                })
              "
            />
          </p>
        </div>
      </div>
    </div>
    <div
      class="flex h-full justify-between self-end flex-col p-2 pt-1 md:p-4 md:pt-2 leading-normal w-full"
    >
      <h2
        class="mb-2 text-xl font-bold tracking-tight text-violet-title dark:text-white"
      >
        <slot name="default" />
      </h2>
    </div>
  </router-link>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { CategoryPictureLicencing } from "../Categories/constants";

const props = defineProps<{
  to: { name: string; query: Record<string, string | undefined> };
  picture?: CategoryPictureLicencing & { url: string };
}>();

const imageAuthor = computed(
  () =>
    `<a target="_blank" class="underline font-medium" href="${props.picture?.author?.url}">${props.picture?.author?.name}</a>`
);
const imageSource = computed(
  () =>
    `<a target="_blank" class="underline font-medium" href="${props.picture?.source?.url}">${props.picture?.source?.name}</a>`
);
</script>
<style>
.custom-overlay {
  background-image: linear-gradient(
    180deg,
    rgba(0, 0, 0, 0) 0%,
    rgba(0, 0, 0, 0) 25%,
    rgba(2, 0, 36, 0.75) 90%,
    rgba(2, 0, 36, 0.85) 100%
  );
  transition:
    opacity 0.1s ease-in-out,
    visibility 0.1s ease-in-out;
}
</style>
