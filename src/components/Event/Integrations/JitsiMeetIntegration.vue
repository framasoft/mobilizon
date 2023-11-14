<template>
  <div class="jitsi-meet">
    <div class="jitsi-meet-video" v-if="metadata">
      <iframe
        allow="camera; microphone; fullscreen; display-capture; autoplay"
        :src="metadata.value"
        style="height: 100%; width: 100%; border: 0px"
      ></iframe>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IEventMetadataDescription } from "@/types/event-metadata";
defineProps<{ metadata: IEventMetadataDescription }>();
</script>
<style lang="scss" scoped>
.jitsi-meet {
  .jitsi-meet-video {
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
