<template>
  <div class="multi-card-event">
    <event-card
      class="event-card"
      v-for="event in events"
      :event="event"
      :key="event.uuid"
    />
  </div>
</template>
<script lang="ts">
import { IEvent } from "@/types/event.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import EventCard from "./EventCard.vue";
@Component({
  components: {
    EventCard,
  },
})
export default class MultiCard extends Vue {
  @Prop({ type: Array as PropType<IEvent[]>, required: true })
  events!: IEvent[];
}
</script>
<style lang="scss" scoped>
.multi-card-event {
  display: grid;
  grid-auto-rows: 1fr;
  grid-column-gap: 30px;
  grid-row-gap: 30px;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  .event-card {
    height: 100%;
    display: flex;
    flex-direction: column;
  }
}
</style>
