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
<script lang="ts">
import { IEventMetadataDescription } from "@/types/event-metadata";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class TwitchIntegration extends Vue {
  @Prop({ type: Object as PropType<IEventMetadataDescription>, required: true })
  metadata!: IEventMetadataDescription;

  get channelName(): string | null {
    if (this.metadata.pattern) {
      const matches = this.metadata.pattern.exec(this.metadata.value);
      if (matches && matches[1]) {
        return matches[1];
      }
    }
    return null;
  }

  get origin(): string {
    return window.location.hostname;
  }
}
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
