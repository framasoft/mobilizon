<template>
  <span class="tag">
    <span>
      <slot />
    </span>
  </span>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";

@Component
export default class Tag extends Vue {}
</script>

<style lang="scss" scoped>
span.tag {
  background: $purple-3;
  color: $violet-2;
  text-transform: uppercase;
  &::before {
    content: "#";
  }
}
</style>
