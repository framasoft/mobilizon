<template>
  <div class="empty-content" :class="{ inline }" role="note">
    <b-icon :icon="icon" size="is-large" />
    <h2 class="empty-content__title">
      <!-- @slot Mandatory title -->
      <slot />
    </h2>
    <p v-show="$slots.desc">
      <!-- @slot Optional description -->
      <slot name="desc" />
    </p>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class EmptyContent extends Vue {
  @Prop({ type: String, required: true }) icon!: string;
  @Prop({ type: Boolean, required: false, default: false }) inline!: boolean;
}
</script>

<style lang="scss">
.empty-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 20vh;
  &__title {
    margin-bottom: 10px;
  }
  &.inline {
    margin-top: 5vh;
  }
}
</style>
