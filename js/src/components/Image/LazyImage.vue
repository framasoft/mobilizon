<template>
  <div ref="wrapper" class="wrapper" v-bind="$attrs">
    <div class="relative container">
      <!-- Show the placeholder as background -->
      <blurhash-img
        v-if="blurhash"
        :hash="blurhash"
        :aspect-ratio="height / width"
        class="top-0 left-0 transition-opacity duration-500"
        :class="isLoaded ? 'opacity-0' : 'opacity-100'"
      />

      <!-- Show the real image on the top and fade in after loading -->
      <img
        ref="image"
        :width="width"
        :height="height"
        class="absolute top-0 left-0 transition-opacity duration-500"
        :class="{ isLoaded: isLoaded ? 'opacity-100' : 'opacity-0', rounded }"
        alt=""
        src=""
      />
    </div>
  </div>
</template>

<script lang="ts">
import { Prop, Component, Vue, Ref, Watch } from "vue-property-decorator";
import BlurhashImg from "./BlurhashImg.vue";

@Component({
  components: {
    BlurhashImg,
  },
})
export default class LazyImage extends Vue {
  @Prop({ type: String, required: true }) src!: string;
  @Prop({ type: String, required: false, default: null }) blurhash!: string;
  @Prop({ type: Number, default: 1 }) width!: number;
  @Prop({ type: Number, default: 1 }) height!: number;
  @Prop({ type: Boolean, default: false }) rounded!: boolean;

  inheritAttrs = false;
  isLoaded = false;

  observer!: IntersectionObserver;

  @Ref("wrapper") readonly wrapper!: any;
  @Ref("image") image!: any;

  mounted(): void {
    this.observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        this.onEnter();
      }
    });

    this.observer.observe(this.wrapper);
  }

  unmounted(): void {
    this.observer.disconnect();
  }

  onEnter(): void {
    // Image is visible (means: has entered the viewport),
    // so start loading by setting the src attribute
    if (this.image) {
      this.image.src = this.src;

      this.image.onload = () => {
        // Image is loaded, so start fading in
        this.isLoaded = true;
      };
    }
  }

  @Watch("src")
  updateImageWithSrcChange(): void {
    this.onEnter();
  }
}
</script>
<style lang="scss" scoped>
.relative {
  position: relative;
}
.absolute {
  position: absolute;
}
.top-0 {
  top: 0;
}
.left-0 {
  left: 0;
}
.opacity-100 {
  opacity: 100%;
}
.opacity-0 {
  opacity: 0;
}
.transition-opacity {
  transition-property: opacity;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}
.duration-500 {
  transition-duration: 0.5s;
}
.wrapper,
.container {
  display: flex;
  flex: 1;
}
img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 50% 50%;
  &.rounded {
    border-radius: 8px;
  }
}
</style>
