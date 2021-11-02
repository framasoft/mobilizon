<template>
  <div class="events-wrapper">
    <event-minimalist-card
      v-for="event in events"
      :key="event.id"
      :event="event"
      :isCurrentActorMember="isCurrentActorMember"
      :showOrganizer="showOrganizer"
    />
  </div>
</template>
<script lang="ts">
import { IEvent } from "@/types/event.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import EventMinimalistCard from "./EventMinimalistCard.vue";

@Component({
  components: {
    EventMinimalistCard,
  },
})
export default class MultiEventMinimalistCard extends Vue {
  @Prop({ type: Array as PropType<IEvent[]>, required: true })
  events!: IEvent[];
  @Prop({ required: false, type: Boolean, default: false })
  isCurrentActorMember!: boolean;
  @Prop({ required: false, type: Boolean, default: false })
  showOrganizer!: boolean;
}
</script>
<style lang="scss" scoped>
.events-wrapper {
  display: grid;
  grid-gap: 20px;
  grid-template: 1fr;
}
</style>
