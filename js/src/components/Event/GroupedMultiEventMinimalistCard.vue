<template>
  <div class="events-wrapper">
    <div class="month-group" v-for="key of keys" :key="key">
      <h2 class="is-size-5 month-name">
        {{ monthName(groupEvents(key)[0]) }}
      </h2>
      <event-minimalist-card
        class="py-4"
        v-for="event in groupEvents(key)"
        :key="event.id"
        :event="event"
        :isCurrentActorMember="isCurrentActorMember"
      />
    </div>
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
export default class GroupedMultiEventMinimalistCard extends Vue {
  @Prop({ type: Array as PropType<IEvent[]>, required: true })
  events!: IEvent[];
  @Prop({ required: false, type: Boolean, default: false })
  isCurrentActorMember!: boolean;

  get monthlyGroupedEvents(): Map<string, IEvent[]> {
    return this.events.reduce((acc: Map<string, IEvent[]>, event: IEvent) => {
      const beginsOn = new Date(event.beginsOn);
      const month = `${beginsOn.getUTCMonth()}-${beginsOn.getUTCFullYear()}`;
      const monthEvents = acc.get(month) || [];
      acc.set(month, [...monthEvents, event]);
      return acc;
    }, new Map());
  }

  get keys(): string[] {
    return Array.from(this.monthlyGroupedEvents.keys()).sort((a, b) =>
      b.localeCompare(a)
    );
  }

  groupEvents(key: string): IEvent[] {
    return this.monthlyGroupedEvents.get(key) || [];
  }

  monthName(event: IEvent): string {
    const beginsOn = new Date(event.beginsOn);
    return new Intl.DateTimeFormat(undefined, {
      month: "long",
      year: "numeric",
    }).format(beginsOn);
  }
}
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
      background: $orange-3;
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
