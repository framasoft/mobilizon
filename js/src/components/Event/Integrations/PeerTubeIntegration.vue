<template>
  <div class="peertube">
    <div class="peertube-video" v-if="videoDetails">
      <iframe
        width="100%"
        height="100%"
        sandbox="allow-same-origin allow-scripts allow-popups"
        :src="`https://${videoDetails.host}/videos/embed/${videoDetails.uuid}`"
        frameborder="0"
        allowfullscreen
      ></iframe>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IEventMetadataDescription } from "@/types/event-metadata";
import { computed } from "vue";

const props = defineProps<{ metadata: IEventMetadataDescription }>();

const videoDetails = computed((): { host: string; uuid: string } | null => {
  if (props.metadata.pattern) {
    const matches = props.metadata.pattern.exec(props.metadata.value);
    if (matches && matches[1] && matches[2]) {
      return { host: matches[1], uuid: matches[2] };
    }
  }
  return null;
});
</script>
<style lang="scss" scoped>
.peertube {
  .peertube-video {
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
