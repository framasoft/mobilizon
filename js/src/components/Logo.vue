<template>
    <img svg-inline src="../assets/mobilizon_logo.svg" alt="Mobilizon" :class="{invert: invert}" height="40px">
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
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
