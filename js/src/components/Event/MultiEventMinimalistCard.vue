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
<script lang="ts" setup>
import { IEvent } from "@/types/event.model";
import EventMinimalistCard from "./EventMinimalistCard.vue";

withDefaults(
  defineProps<{
    events: IEvent[];
    isCurrentActorMember?: boolean;
    showOrganizer?: boolean;
  }>(),
  {
    isCurrentActorMember: false,
    showOrganizer: false,
  }
);
</script>
<style lang="scss" scoped>
.events-wrapper {
  display: grid;
  grid-gap: 20px;
  grid-template: 1fr;
}
</style>
