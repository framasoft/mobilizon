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
<script lang="ts">
import { IEventMetadataDescription } from "@/types/event-metadata";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class JitsiMeetIntegration extends Vue {
  @Prop({ type: Object as PropType<IEventMetadataDescription>, required: true })
  metadata!: IEventMetadataDescription;
}
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
