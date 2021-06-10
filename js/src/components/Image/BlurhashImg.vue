<template>
  <canvas ref="canvas" width="32" height="32" />
</template>

<script lang="ts">
import { decode } from "blurhash";
import { Component, Prop, Ref, Vue } from "vue-property-decorator";

@Component
export default class extends Vue {
  @Prop({ type: String, required: true }) hash!: string;
  @Prop({ type: Number, default: 1 }) aspectRatio!: string;

  @Ref("canvas") readonly canvas!: any;

  mounted(): void {
    const pixels = decode(this.hash, 32, 32);
    const imageData = new ImageData(pixels, 32, 32);
    const context = this.canvas.getContext("2d");
    context.putImageData(imageData, 0, 0);
  }
}
</script>
<style lang="scss" scoped>
canvas {
  position: absolute;
  top: 0px;
  right: 0px;
  bottom: 0px;
  left: 0px;
  width: 100%;
  height: 100%;
}
</style>
