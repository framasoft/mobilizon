<template>
  <div
    class="flex flex-col items-center"
    :class="{ 'mt-20 mb-10': inline, 'mt-80': !inline, 'text-center': center }"
    role="note"
  >
    <o-icon :icon="icon" customSize="48" />
    <h2 class="mb-3">
      <!-- @slot Mandatory title -->
      <slot />
    </h2>
    <p v-show="slots.desc" :class="descriptionClasses">
      <!-- @slot Optional description -->
      <slot name="desc" />
    </p>
  </div>
</template>
<script lang="ts" setup>
import { useSlots } from "vue";

withDefaults(
  defineProps<{
    icon: string;
    descriptionClasses?: string;
    inline?: boolean;
    center?: boolean;
  }>(),
  { descriptionClasses: "", inline: false, center: false }
);

const slots = useSlots();
</script>
