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
import { Component, Prop, Vue } from "vue-property-decorator";
import LazyImage from "../Image/LazyImage.vue";

@Component({
  components: {
    LazyImage,
  },
})
export default class LazyImageWrapper extends Vue {
  @Prop({ required: true, default: null })
  picture!: IMedia | null;

  get pictureOrDefault(): Partial<IMedia> {
    return {
      url:
        this?.picture === null
          ? "/img/mobilizon_default_card.png"
          : this?.picture?.url,
      metadata: {
        width: this?.picture?.metadata?.width || 630,
        height: this?.picture?.metadata?.height || 350,
        blurhash:
          this?.picture?.metadata?.blurhash ||
          "MCHKI4El-P-U}+={R-WWoes,Iu-P=?R,xD",
      },
    };
  }
}
</script>
