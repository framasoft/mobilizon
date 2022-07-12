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
<script lang="ts" setup>
import { IEvent } from "@/types/event.model";

import EventCard from "./EventCard.vue";

defineProps<{
  events: IEvent[];
}>();
</script>
<style lang="scss" scoped>
.multi-card-event {
  display: grid;
  grid-auto-rows: 1fr;
  grid-column-gap: 20px;
  grid-row-gap: 30px;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  .event-card {
    height: 100%;
    display: flex;
    flex-direction: column;
  }
}
</style>
