<template>
  <!-- <img src="../assets/mobilizon_logo.svg" alt="Mobilizon" :class="{ invert: invert }" height="40" /> -->
  <MobilizonLogo />
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
// eslint-disable-next-line @typescript-eslint/ban-ts-ignore
// @ts-ignore
import MobilizonLogo from "../assets/mobilizon_logo.svg";
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
@import "../variables.scss";

svg {
  fill: $primary;

  &.invert {
    fill: $secondary;
  }
}
</style>
