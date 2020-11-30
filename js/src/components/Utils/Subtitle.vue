<template>
  <h2>
    <span>
      <slot />
    </span>
  </h2>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";

@Component
export default class Subtitle extends Vue {}
</script>
<style lang="scss" scoped>
h2 {
  display: block;
  margin: 15px 0 30px;

  span {
    background: $secondary;
    display: inline;
    padding: 3px 8px;
    color: #3a384c;
    font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial,
      serif;
    font-weight: 400;
    font-size: 32px;
  }
}
</style>
