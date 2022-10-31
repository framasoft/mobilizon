<template>
  <div
    class="bg-white dark:bg-mbz-purple rounded-lg flex space-x-4 items-center"
    :class="{ 'flex-col p-4 shadow-md sm:p-8 pb-10 w-80': !inline }"
  >
    <div class="flex pl-2">
      <figure class="w-12 h-12" v-if="actor.avatar">
        <img
          class="rounded-full object-cover h-full"
          :src="actor.avatar.url"
          alt=""
          width="48"
          height="48"
          loading="lazy"
        />
      </figure>
      <AccountCircle
        v-else
        :size="inline ? 24 : 48"
        class="ltr:-mr-0.5 rtl:-ml-0.5"
      />
    </div>
    <div :class="{ 'text-center': !inline }" class="overflow-hidden w-full">
      <h5
        class="text-xl font-medium violet-title tracking-tight text-gray-900 dark:text-gray-200 whitespace-pre-line line-clamp-2"
      >
        {{ displayName(actor) }}
      </h5>
      <p class="text-gray-500 dark:text-gray-200 truncate" v-if="actor.name">
        <span dir="ltr">@{{ usernameWithDomain(actor) }}</span>
      </p>
      <div
        v-if="full"
        class="only-first-child"
        :class="{
          'line-clamp-3': limit,
          'line-clamp-10': !limit,
        }"
        v-html="actor.summary"
      />
    </div>
  </div>
  <!-- <div
    class="p-4 bg-white rounded-lg shadow-md sm:p-8 flex items-center space-x-4"
    dir="auto"
  >
    <div class="flex-shrink-0">
      <figure class="w-12 h-12" v-if="actor.avatar">
        <img
          class="rounded-lg"
          :src="actor.avatar.url"
          alt=""
          width="48"
          height="48"
        />
      </figure>
      <o-icon
        v-else
        size="large"
        icon="account-circle"
        class="ltr:-mr-0.5 rtl:-ml-0.5"
      />
    </div>

    <div class="flex-1 min-w-0">
      <h5 class="text-xl font-medium violet-title tracking-tight text-gray-900">
        {{ displayName(actor) }}
      </h5>
      <p class="text-gray-500 truncate" v-if="actor.name">
        <span dir="ltr">@{{ usernameWithDomain(actor) }}</span>
      </p>
      <div
        v-if="full"
        class="line-clamp-3"
        :class="{ limit: limit }"
        v-html="actor.summary"
      />
    </div>
  </div> -->
</template>
<script lang="ts" setup>
import { displayName, IActor, usernameWithDomain } from "../../types/actor";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";

withDefaults(
  defineProps<{
    actor: IActor;
    full?: boolean;
    inline?: boolean;
    popover?: boolean;
    limit?: boolean;
  }>(),
  {
    full: false,
    inline: false,
    popover: false,
    limit: true,
  }
);
</script>
<style scoped>
.only-first-child :deep(:not(:first-child)) {
  display: none;
}
</style>
