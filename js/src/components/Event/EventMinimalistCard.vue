<template>
  <router-link
    class="event-minimalist-card-wrapper"
    :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
  >
    <date-calendar-icon class="calendar-icon" :date="event.beginsOn" />
    <div class="title-info-wrapper">
      <p class="event-minimalist-title">{{ event.title }}</p>
      <p v-if="event.physicalAddress" class="has-text-grey">
        {{ event.physicalAddress.description }}
      </p>
      <p v-else>3 demandes de participation à traiter</p>
    </div>
  </router-link>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IEvent } from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import RouteName from "../../router/name";

@Component({
  components: {
    DateCalendarIcon,
  },
})
export default class EventMinimalistCard extends Vue {
  @Prop({ required: true, type: Object }) event!: IEvent;

  RouteName = RouteName;
}
</script>
<style lang="scss" scoped>
.event-minimalist-card-wrapper {
  display: flex;
  width: 100%;
  color: initial;
  align-items: flex-start;

  .calendar-icon {
    margin-right: 1rem;
  }

  .title-info-wrapper {
    flex: 2;

    .event-minimalist-title {
      color: #3c376e;
      font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial, serif;
      font-size: 1.25rem;
      font-weight: 700;
    }
  }
}
</style>
