<template>
  <div
    class="inline-flex items-start gap-2 bg-white dark:bg-violet-1 dark:text-white p-2 rounded-md"
  >
    <div class="flex-none">
      <figure v-if="actor.avatar">
        <img
          class="rounded-xl"
          :src="actor.avatar.url"
          alt=""
          width="36"
          height="36"
          loading="lazy"
        />
      </figure>
      <AccountCircle :size="36" v-else />
    </div>

    <div class="flex-auto">
      <p class="text-lg line-clamp-3 md:line-clamp-2 max-w-xl">
        {{ displayName(actor) }}
      </p>
      <p class="text-sm text-gray-500 dark:text-gray-300 truncate">
        @{{ usernameWithDomain(actor) }}
      </p>
    </div>
    <div class="flex pr-2 self-center">
      <Email />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { displayName, IActor, usernameWithDomain } from "../../types/actor";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Email from "vue-material-design-icons/Email.vue";

defineProps<{
  actor: IActor;
}>();
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
div.actor-inline {
  align-items: flex-start;
  display: inline-flex;
  text-align: inherit;
  align-items: top;

  div.actor-avatar {
    flex-basis: auto;
    flex-grow: 0;
    flex-shrink: 0;
    // @include margin-right(0.5rem);
  }
  div.actor-name {
    flex-basis: auto;
    flex-grow: 1;
    flex-shrink: 1;
    text-align: inherit;
  }
}
</style>
