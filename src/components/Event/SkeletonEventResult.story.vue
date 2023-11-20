<template>
  <Story>
    <Variant title="row">
      <SkeletonEventResult />
    </Variant>
    <Variant title="column">
      <SkeletonEventResult view-mode="column" />
    </Variant>
    <Variant title="not minimal">
      <SkeletonEventResult :minimal="false" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import SkeletonEventResult from "./SkeletonEventResult.vue";
</script>
