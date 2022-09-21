<template>
  <div class="etherpad">
    <div class="etherpad-container" v-if="metadata">
      <iframe
        :src="`${metadata.value}?showChat=false&showLineNumbers=false`"
        width="600"
        height="400"
      ></iframe>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IEventMetadataDescription } from "@/types/event-metadata";

defineProps<{ metadata: IEventMetadataDescription }>();
</script>
<style lang="scss" scoped>
.etherpad {
  .etherpad-container {
    padding-top: 56.25%;
    position: relative;
    height: 0;

    iframe {
      position: absolute;
      width: 100%;
      height: 100%;
      top: 0;
    }
  }
}
</style>
