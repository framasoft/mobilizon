<template>
  <div
    class="grid auto-rows-[1fr] gap-x-2 gap-y-4 md:gap-x-6 grid-cols-[repeat(auto-fill,_minmax(250px,_1fr))] justify-items-center"
  >
    <event-card
      class="flex flex-col h-full"
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
