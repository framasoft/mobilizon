<template>
  <div>
    <h2>{{ title }}</h2>
    <div class="eventMetadataBlock">
      <b-icon v-if="icon" :icon="icon" size="is-medium" />
      <p :class="{ 'padding-left': icon }">
        <slot></slot>
      </p>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class EventMetadataBlock extends Vue {
  @Prop({ required: false, type: String }) icon!: string;

  @Prop({ required: true, type: String }) title!: string;
}
</script>
<style lang="scss" scoped>
h2 {
  font-size: 1.8rem;
  font-weight: 500;
  color: #f7ba30;
}

div.eventMetadataBlock {
  display: flex;
  align-items: center;
  margin-bottom: 1.75rem;

  p {
    flex: 1;

    &.padding-left {
      padding-left: 20px;
    }
  }
}
</style>
