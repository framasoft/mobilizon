<template>
  <lazy-image
    v-if="pictureOrDefault.url !== undefined"
    :src="pictureOrDefault.url"
    :width="pictureOrDefault.metadata.width"
    :height="pictureOrDefault.metadata.height"
    :blurhash="pictureOrDefault.metadata.blurhash"
  />
</template>
<script lang="ts">
import { IMedia } from "@/types/media.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
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

@Component({
  components: {
    LazyImage,
  },
})
export default class LazyImageWrapper extends Vue {
  @Prop({ required: false, type: Object as PropType<IMedia | null> })
  picture!: IMedia | null;

  get pictureOrDefault(): Partial<IMedia> {
    if (this.picture === null) {
      return DEFAULT_PICTURE;
    }
    return {
      url: this?.picture?.url,
      metadata: {
        width: this?.picture?.metadata?.width,
        height: this?.picture?.metadata?.height,
        blurhash: this?.picture?.metadata?.blurhash,
      },
    };
  }
}
</script>
