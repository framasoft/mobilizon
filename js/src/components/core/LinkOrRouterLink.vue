<template>
  <a
    v-if="isInternal"
    :target="newTab ? '_blank' : undefined"
    :href="href"
    rel="noopener noreferrer"
    v-bind="$attrs"
  >
    <slot />
  </a>
  <router-link :to="to" v-bind="$attrs" v-else>
    <slot />
  </router-link>
</template>
<script lang="ts">
// use normal <script> to declare options
export default {
  inheritAttrs: false,
};
</script>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    to: { name: string; params?: any; query?: any } | string;
    isInternal?: boolean;
    newTab?: boolean;
  }>(),
  { isInternal: true, newTab: true }
);

const href = computed(() => {
  if (typeof props.to === "string" || props.to instanceof String) {
    return props.to as string;
  }
  return undefined;
});
</script>
