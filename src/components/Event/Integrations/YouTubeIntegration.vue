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
<script lang="ts" setup>
import { IEventMetadataDescription } from "@/types/event-metadata";
import { computed } from "vue";

const props = defineProps<{ metadata: IEventMetadataDescription }>();

const videoID = computed((): string | null => {
  if (props.metadata.pattern) {
    const matches = props.metadata.pattern.exec(props.metadata.value);
    if (matches && matches[1]) {
      return matches[1];
    }
  }
  return null;
});
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
