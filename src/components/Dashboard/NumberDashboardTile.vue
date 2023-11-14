<template>
  <article
    :class="{ 'bg-white dark:bg-black mb-4 shadow-md rounded p-4': style }"
  >
    <p class="text-violet-3 text-4xl font-bold">{{ number }}</p>
    <slot name="subtitle">
      {{ subtitle }}
    </slot>
  </article>
</template>
<script lang="ts" setup>
withDefaults(
  defineProps<{
    number?: number;
    subtitle?: string;
    style?: boolean;
  }>(),
  { style: true }
);
</script>
