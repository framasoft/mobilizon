<template>
  <section>
    <h2 :class="{ privateSection }">
      <b-icon :icon="icon" />
      <span>{{ title }}</span>
    </h2>
    <slot></slot>
  </section>
</template>

<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";

@Component
export default class GroupSection extends Vue {
  @Prop({ required: true, type: String }) title!: string;
  @Prop({ required: true, type: String }) icon!: string;
  @Prop({ required: false, type: Boolean, default: true }) privateSection!: boolean;
}
</script>
<style lang="scss" scoped>
@import "@/variables.scss";

h2 {
  display: flex;
  align-items: stretch;
  margin: 15px 0 30px;

  /deep/ span {
    background: $secondary;
    display: inline;
    padding: 3px 8px;
    color: #3a384c;
    font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial, serif;
    font-weight: 500;
    font-size: 30px;
    flex: 1;
  }

  /deep/ span.icon {
    flex: 0;
    height: 100%;
  }
}

h2.privateSection /deep/ span {
  color: $violet-2;
  background: $purple-2;
}
</style>
