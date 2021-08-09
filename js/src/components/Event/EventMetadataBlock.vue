<template>
  <div>
    <h2>{{ title }}</h2>
    <div class="eventMetadataBlock">
      <!-- Custom icons -->
      <span
        class="icon is-medium"
        v-if="icon && icon.substring(0, 7) === 'mz:icon'"
      >
        <img
          :src="`/img/${icon.substring(8)}_monochrome.svg`"
          width="32"
          height="32"
        />
      </span>
      <b-icon v-else-if="icon" :icon="icon" size="is-medium" />
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
  color: $violet;
}

div.eventMetadataBlock {
  display: flex;
  align-items: center;
  margin-bottom: 1.75rem;

  p {
    overflow: hidden;

    &.padding-left {
      padding: 0 20px;

      a {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
    }
  }
}
</style>
