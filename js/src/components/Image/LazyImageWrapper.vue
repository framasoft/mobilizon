<template>
  <lazy-image
    v-if="pictureOrDefault.url !== undefined"
    :src="pictureOrDefault.url"
    :width="pictureOrDefault.metadata.width"
    :height="pictureOrDefault.metadata.height"
    :blurhash="pictureOrDefault.metadata.blurhash"
    :rounded="rounded"
  />
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { IMedia } from "@/types/media.model";
import LazyImage from "../Image/LazyImage.vue";

const DEFAULT_CARD_URL = "/img/mobilizon_default_card.png";
const DEFAULT_BLURHASH = "MCHKI4El-P-U}+={R-WWoes,Iu-P=?R,xD";
const DEFAULT_WIDTH = 630;
const DEFAULT_HEIGHT = 350;
const DEFAULT_PICTURE = {
  url: DEFAULT_CARD_URL,
  metadata: {
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT,
    blurhash: DEFAULT_BLURHASH,
  },
};

const props = withDefaults(
  defineProps<{
    picture?: IMedia | null;
    rounded?: boolean;
  }>(),
  {
    rounded: false,
  }
);

const pictureOrDefault = computed(() => {
  if (props.picture === null) {
    return DEFAULT_PICTURE;
  }
  return {
    url: props?.picture?.url,
    metadata: {
      width: props?.picture?.metadata?.width,
      height: props?.picture?.metadata?.height,
      blurhash: props?.picture?.metadata?.blurhash,
    },
  };
});
</script>
