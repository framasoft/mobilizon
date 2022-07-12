<template>
  <div class="observer" ref="observed" />
</template>

<script lang="ts" setup>
import "intersection-observer";
import { onMounted, onUnmounted, ref } from "vue";

const props = withDefaults(
  defineProps<{
    options?: Record<string, any>;
  }>(),
  { options: () => ({}) }
);

const observer = ref<IntersectionObserver>();
const observed = ref<HTMLElement>();
const emit = defineEmits(["intersect"]);

onMounted(() => {
  observer.value = new IntersectionObserver(([entry]) => {
    if (entry && entry.isIntersecting) {
      emit("intersect");
    }
  }, props.options);

  if (observed.value) {
    observer.value.observe(observed.value);
  }
});

onUnmounted(() => {
  observer.value?.disconnect();
});
</script>
