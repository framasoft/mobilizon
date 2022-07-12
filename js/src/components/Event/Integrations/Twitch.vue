<template>
  <div class="twitch">
    <div class="twitch-video" v-if="channelName">
      <iframe
        :src="`https://player.twitch.tv/?channel=${channelName}&parent=${origin}&autoplay=false`"
        frameborder="0"
        scrolling="no"
        allowfullscreen="true"
        height="100%"
        width="100%"
      >
      </iframe>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IEventMetadataDescription } from "@/types/event-metadata";
import { computed } from "vue";

const props = defineProps<{ metadata: IEventMetadataDescription }>();

const channelName = computed((): string | null => {
  if (props.metadata.pattern) {
    const matches = props.metadata.pattern.exec(props.metadata.value);
    if (matches && matches[1]) {
      return matches[1];
    }
  }
  return null;
});

const origin = computed((): string => {
  return window.location.hostname;
});
</script>
<style lang="scss" scoped>
.twitch {
  .twitch-video {
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
