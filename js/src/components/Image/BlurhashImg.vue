<template>
  <canvas ref="canvas" width="32" height="32" />
</template>

<script lang="ts" setup>
import { decode } from "blurhash";

import { ref, onMounted } from "vue";

const props = withDefaults(
  defineProps<{
    hash: string;
    aspectRatio?: number;
  }>(),
  { aspectRatio: 1 }
);

const canvas = ref<HTMLCanvasElement | undefined>(undefined);

onMounted(() => {
  try {
    if (canvas.value) {
      const pixels = decode(props.hash, 32, 32);
      const imageData = new ImageData(pixels, 32, 32);
      const context = canvas.value.getContext("2d");
      if (context) {
        context.putImageData(imageData, 0, 0);
      }
    }
  } catch (e) {
    console.error(e);
  }
});
</script>
