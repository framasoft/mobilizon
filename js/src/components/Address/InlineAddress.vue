<template>
  <div
    class="ellipsis"
    :title="
      isDescriptionDifferentFromLocality
        ? `${physicalAddress.description}, ${physicalAddress.locality}`
        : physicalAddress.description
    "
  >
    <b-icon icon="map-marker" />
    <span v-if="isDescriptionDifferentFromLocality">
      {{ physicalAddress.description }},
      {{ physicalAddress.locality }}
    </span>
    <span v-else>
      {{ physicalAddress.description }}
    </span>
  </div>
</template>
<script lang="ts">
import { IAddress } from "@/types/address.model";
import { PropType } from "vue";
import { Prop, Vue, Component } from "vue-property-decorator";

@Component
export default class InlineAddress extends Vue {
  @Prop({ required: true, type: Object as PropType<IAddress> })
  physicalAddress!: IAddress;

  get isDescriptionDifferentFromLocality(): boolean {
    return (
      this.physicalAddress?.description !== this.physicalAddress?.locality &&
      this.physicalAddress?.description !== undefined
    );
  }
}
</script>
<style lang="scss" scoped>
.ellipsis {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
