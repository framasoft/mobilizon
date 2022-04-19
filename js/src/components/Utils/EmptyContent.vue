<template>
  <div
    class="empty-content"
    :class="{ inline, 'text-center': center }"
    role="note"
  >
    <b-icon :icon="icon" size="is-large" />
    <h2 class="empty-content__title">
      <!-- @slot Mandatory title -->
      <slot />
    </h2>
    <p v-show="$slots.desc" :class="descriptionClasses">
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
  @Prop({ type: String, required: false, default: "" })
  descriptionClasses!: string;
  @Prop({ type: Boolean, required: false, default: false }) inline!: boolean;
  @Prop({ type: Boolean, required: false, default: false }) center!: boolean;
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
    margin-bottom: 2vh;
  }
}
</style>
