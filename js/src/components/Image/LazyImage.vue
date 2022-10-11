<template>
  <div ref="wrapper" class="flex-1" v-bind="$attrs">
    <div class="h-full w-full max-w-100 min-h-[10rem]">
      <!-- Show the placeholder as background -->
      <blurhash-img
        v-if="blurhash"
        :hash="blurhash"
        :aspect-ratio="height / width"
        class="transition-opacity duration-500"
        :class="blurhashOpacity"
      />

      <!-- Show the real image on the top and fade in after loading -->
      <img
        ref="image"
        class="transition-opacity duration-500 rounded-lg object-cover mx-auto h-full"
        :class="imageOpacity"
        alt=""
        src=""
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import BlurhashImg from "./BlurhashImg.vue";

import { computed, ref, onMounted, onUnmounted, watchEffect } from "vue";

const props = withDefaults(
  defineProps<{
    src: string;
    blurhash?: string | null;
    width?: number;
    height?: number;
    rounded?: boolean;
  }>(),
  { blurhash: null, width: 100, height: 100, rounded: false }
);

const isLoaded = ref(false);
const observer = ref<IntersectionObserver | null>(null);

const wrapper = ref<HTMLElement | null>(null);
const image = ref<HTMLImageElement | null>(null);

const src = computed(() => props.src);

const isIntersecting = ref(false);

const blurhashOpacity = computed(() =>
  isLoaded.value ? "opacity-0 hidden" : "opacity-100"
);

const imageOpacity = computed(() =>
  isLoaded.value ? "opacity-100" : "opacity-0"
);

onMounted(() => {
  observer.value = new IntersectionObserver((entries) => {
    isIntersecting.value = entries[0].isIntersecting;
  });

  if (wrapper.value) {
    observer.value.observe(wrapper.value);
  }
});

onUnmounted(() => {
  if (observer.value) {
    observer.value.disconnect();
  }
});

watchEffect(() => {
  // Image is visible (means: has entered the viewport),
  // so start loading by setting the src attribute
  if (image.value) {
    image.value.src = src.value;

    image.value.onload = () => {
      // Image is loaded, so start fading in
      isLoaded.value = true;
    };
  }
});
</script>
