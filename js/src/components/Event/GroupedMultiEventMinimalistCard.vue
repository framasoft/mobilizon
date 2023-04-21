<template>
  <div class="flex flex-col gap-6">
    <div class="flex flex-col gap-4" v-for="key of keys" :key="key">
      <h2 class="capitalize inline-block relative">
        {{ monthName(groupEvents(key)[0]) }}
      </h2>
      <event-minimalist-card
        v-for="event in groupEvents(key)"
        :key="event.id"
        :event="event"
        :isCurrentActorMember="isCurrentActorMember"
      />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IEvent } from "@/types/event.model";
import { computed } from "vue";
import EventMinimalistCard from "./EventMinimalistCard.vue";

const props = withDefaults(
  defineProps<{
    events: IEvent[];
    isCurrentActorMember?: boolean;
    order: "ASC" | "DESC";
  }>(),
  { isCurrentActorMember: false, order: "ASC" }
);

const monthlyGroupedEvents = computed((): Map<string, IEvent[]> => {
  return props.events.reduce((acc: Map<string, IEvent[]>, event: IEvent) => {
    const beginsOn = new Date(event.beginsOn);
    const month = `${beginsOn.getUTCFullYear()}-${beginsOn.getUTCMonth()}`;
    const monthEvents = acc.get(month) || [];
    acc.set(month, [...monthEvents, event]);
    return acc;
  }, new Map());
});

const keys = computed((): string[] => {
  return Array.from(monthlyGroupedEvents.value.keys()).sort((a, b) => {
    const aParams = a.split("-").map((x) => parseInt(x, 10)) as [
      number,
      number
    ];
    const aDate = new Date(...aParams);
    const bParams = b.split("-").map((x) => parseInt(x, 10)) as [
      number,
      number
    ];
    const bDate = new Date(...bParams);
    return props.order === "DESC"
      ? bDate.getTime() - aDate.getTime()
      : aDate.getTime() - bDate.getTime();
  });
});

const groupEvents = (key: string): IEvent[] => {
  return monthlyGroupedEvents.value.get(key) || [];
};

const monthName = (event: IEvent): string => {
  const beginsOn = new Date(event.beginsOn);
  return new Intl.DateTimeFormat(undefined, {
    month: "long",
    year: "numeric",
  }).format(beginsOn);
};
</script>
<style lang="scss" scoped>
.events-wrapper {
  display: grid;
  grid-gap: 20px;
  grid-template: 1fr;
}
</style>
