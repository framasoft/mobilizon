<template>
    <img src="../assets/mobilizon_logo.svg" alt="Mobilizon">
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

    img {
        color: #403e56;
        height: 80px;
    }
</style>
