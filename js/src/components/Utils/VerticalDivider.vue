<template>
  <div class="is-divider-vertical" :data-content="dataContent"></div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class VerticalDivider extends Vue {
  @Prop({ default: "Or" }) content!: string;

  get dataContent(): string {
    return this.content.toLocaleUpperCase();
  }
}
</script>
<style lang="scss" scoped>
.is-divider-vertical[data-content]::after {
  background-color: $body-background-color;
}
</style>
