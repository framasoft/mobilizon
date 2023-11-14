<template>
  <div>
    <h2>{{ title }}</h2>
    <div class="flex items-center mb-3 gap-1 eventMetadataBlock">
      <slot name="icon"></slot>
      <!-- Custom icons -->
      <!-- <span
        class="icon is-medium"
        v-if="icon && icon.substring(0, 7) === 'mz:icon'"
      >
        <img
          :src="`/img/${icon.substring(8)}_monochrome.svg`"
          width="32"
          height="32"
        />
      </span>
      <o-icon v-else-if="icon" :icon="icon" size="is-medium" /> -->
      <div class="content-wrapper overflow-hidden w-full">
        <slot></slot>
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
defineProps<{
  title: string;
}>();
</script>
<style lang="scss" scoped>
div.eventMetadataBlock {
  .content-wrapper {
    max-width: calc(100vw - 32px - 20px);

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
