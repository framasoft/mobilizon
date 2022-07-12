<template>
  <div class="events-wrapper">
    <div class="flex flex-col gap-4" v-for="key of keys" :key="key">
      <h2 class="is-size-5 month-name">
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
  }>(),
  { isCurrentActorMember: false }
);

const monthlyGroupedEvents = computed((): Map<string, IEvent[]> => {
  return props.events.reduce((acc: Map<string, IEvent[]>, event: IEvent) => {
    const beginsOn = new Date(event.beginsOn);
    const month = `${beginsOn.getUTCMonth()}-${beginsOn.getUTCFullYear()}`;
    const monthEvents = acc.get(month) || [];
    acc.set(month, [...monthEvents, event]);
    return acc;
  }, new Map());
});

const keys = computed((): string[] => {
  return Array.from(monthlyGroupedEvents.value.keys()).sort((a, b) =>
    b.localeCompare(a)
  );
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
.month-group {
  .month-name {
    text-transform: capitalize;
    text-transform: capitalize;
    display: inline-block;
    position: relative;
    font-size: 1.3rem;

    &::after {
      position: absolute;
      left: 0;
      right: 0;
      top: 100%;
      content: "";
      width: calc(100% + 30px);
      height: 3px;
      max-width: 150px;
    }
  }
}
</style>
