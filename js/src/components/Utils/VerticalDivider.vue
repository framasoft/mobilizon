<template>
  <div class="is-divider-vertical" :data-content="dataContent"></div>
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(defineProps<{ content?: string }>(), {
  content: "Or",
});

const dataContent = computed((): string => {
  return props.content.toLocaleUpperCase();
});
</script>
<style lang="scss" scoped>
.is-divider-vertical[data-content]::after {
  background-color: $body-background-color;
}
</style>
