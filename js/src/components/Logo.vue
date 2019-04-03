<template>
    <span class="logo" v-bind:class="{ invert }">M<span class="accent">o</span>b<span class="accent">ı</span>l<span class="accent">ı</span>z<span class="accent">o</span>n</span>
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
    @import "~typeface-signika/index.css";

    .logo {
        font-size: 3.5em;
        color: $primary;
        font-weight: 400;
        font-family: Signika,serif;

        &.invert {
            color: $secondary;
        }

        span.accent::after {
            content: "̇"; // U+0307
            color: #fff;
        }
    }
</style>
