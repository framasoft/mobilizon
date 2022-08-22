<template>
  <span
    class="rounded-md my-1 truncate text-sm text-violet-title px-2 py-1"
    :class="[typeClasses, capitalize]"
  >
    <slot />
  </span>
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    variant?: "info" | "danger" | "warning" | "light";
    capitalize: boolean;
  }>(),
  { variant: "light", capitalize: false }
);

const typeClasses = computed(() => {
  switch (props.variant) {
    default:
    case "light":
      return "bg-purple-3 dark:text-violet-3";
    case "info":
      return "bg-mbz-info dark:text-white";
    case "warning":
      return "bg-yellow-1";
    case "danger":
      return "bg-mbz-danger dark:text-white";
  }
});
</script>

<style lang="scss" scoped>
span.tag {
  &:not(.category)::before {
    content: "#";
  }
}
</style>
