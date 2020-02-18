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
  background: #ecebf7;
  color: #8e8bae;
  text-transform: uppercase;
  &::before {
    content: "#";
  }
}
</style>
