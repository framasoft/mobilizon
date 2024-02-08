<template>
  <span
    class="rounded-md truncate text-sm text-black px-2 py-1"
    :class="[
      typeClasses,
      capitalize,
      withHashTag ? `before:content-['#']` : '',
    ]"
  >
    <slot />
  </span>
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    variant?: "info" | "danger" | "warning" | "light" | "primary";
    capitalize?: boolean;
    withHashTag?: boolean;
  }>(),
  { variant: "light", capitalize: false, withHashTag: false }
);

const typeClasses = computed(() => {
  switch (props.variant) {
    default:
    case "light":
      return "bg-purple-3 dark:text-violet-3";
    case "info":
      return "bg-mbz-info dark:text-black";
    case "warning":
      return "bg-yellow-1";
    case "danger":
      return "bg-mbz-danger dark:text-white";
  }
});
</script>

<style lang="scss" scoped>
span.withHashTag::before {
  content: "#";
}
</style>
