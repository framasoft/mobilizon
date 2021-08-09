<template>
  <div class="youtube">
    <div class="youtube-video" v-if="videoID">
      <iframe
        width="100%"
        height="100%"
        :src="`https://www.youtube.com/embed/${videoID}`"
        title="YouTube video player"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
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
export default class YouTubeIntegration extends Vue {
  @Prop({ type: Object as PropType<IEventMetadataDescription>, required: true })
  metadata!: IEventMetadataDescription;

  get videoID(): string | null {
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
.youtube {
  .youtube-video {
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
