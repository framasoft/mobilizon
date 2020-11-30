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
      <p v-else>
        <span v-if="event.options.maximumAttendeeCapacity !== 0">
          {{
            $tc(
              "{available}/{capacity} available places",
              event.options.maximumAttendeeCapacity -
                event.participantStats.participant,
              {
                available:
                  event.options.maximumAttendeeCapacity -
                  event.participantStats.participant,
                capacity: event.options.maximumAttendeeCapacity,
              }
            )
          }}
        </span>
        <span v-else>
          {{
            $tc("{count} participants", event.participantStats.participant, {
              count: event.participantStats.participant,
            })
          }}
        </span>
        <span v-if="event.participantStats.notApproved > 0">
          <b-button
            type="is-text"
            @click="
              gotToWithCheck(participation, {
                name: RouteName.PARTICIPATIONS,
                query: { role: ParticipantRole.NOT_APPROVED },
                params: { eventId: event.uuid },
              })
            "
          >
            {{
              $tc(
                "{count} requests waiting",
                event.participantStats.notApproved,
                {
                  count: event.participantStats.notApproved,
                }
              )
            }}
          </b-button>
        </span>
      </p>
    </div>
  </router-link>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IEvent } from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { ParticipantRole } from "@/types/enums";
import RouteName from "../../router/name";

@Component({
  components: {
    DateCalendarIcon,
  },
})
export default class EventMinimalistCard extends Vue {
  @Prop({ required: true, type: Object }) event!: IEvent;

  RouteName = RouteName;

  ParticipantRole = ParticipantRole;
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
      font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial,
        serif;
      font-size: 1.25rem;
      font-weight: 700;
    }
  }
}
</style>
