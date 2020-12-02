<template>
  <mobilizon-logo />
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import MobilizonLogo from "../assets/mobilizon_logo.svg";
// TODO: Jest does not like the ?inline after the import path

@Component({
  components: {
    MobilizonLogo,
  },
})
export default class Logo extends Vue {
  @Prop({ type: Boolean, required: false, default: false }) invert!: boolean;
}
</script>
<style lang="scss" scoped>
svg {
  fill: $background-color;

  &.invert {
    fill: $secondary;
  }
}
</style>
