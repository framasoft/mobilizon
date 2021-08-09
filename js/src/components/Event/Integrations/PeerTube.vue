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
<script lang="ts">
import { IEventMetadataDescription } from "@/types/event-metadata";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class PeerTubeIntegration extends Vue {
  @Prop({ type: Object as PropType<IEventMetadataDescription>, required: true })
  metadata!: IEventMetadataDescription;

  get videoDetails(): { host: string; uuid: string } | null {
    if (this.metadata.pattern) {
      const matches = this.metadata.pattern.exec(this.metadata.value);
      if (matches && matches[1] && matches[2]) {
        return { host: matches[1], uuid: matches[2] };
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
