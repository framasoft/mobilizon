<template>
  <v-popover
    offset="16"
    trigger="hover"
    class="popover"
    :class="{ inline, clickable: actor && actor.type === ActorType.GROUP }"
  >
    <slot></slot>
    <template slot="popover" class="popover">
      <actor-card :full="true" :actor="actor" :popover="true" />
    </template>
  </v-popover>
</template>
<script lang="ts">
import { ActorType } from "@/types/enums";
import { Component, Vue, Prop } from "vue-property-decorator";
import { IActor } from "../../types/actor";
import ActorCard from "./ActorCard.vue";

@Component({
  components: {
    ActorCard,
  },
})
export default class PopoverActorCard extends Vue {
  @Prop({ required: true, type: Object }) actor!: IActor;

  @Prop({ required: false, type: Boolean, default: false }) inline!: boolean;

  ActorType = ActorType;
}
</script>

<style lang="scss" scoped>
.inline {
  display: inline;
}
.popover {
  cursor: default;
}
.clickable {
  cursor: pointer;
}
</style>
