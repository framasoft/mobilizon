<template>
  <router-link
    class="event-minimalist-card-wrapper"
    dir="auto"
    :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
  >
    <div class="event-preview mr-0 ml-0">
      <div>
        <div class="date-component">
          <date-calendar-icon :date="event.beginsOn" :small="true" />
        </div>
        <lazy-image-wrapper
          :picture="event.picture"
          :rounded="true"
          style="height: 100%; position: absolute; top: 0; left: 0; width: 100%"
        />
      </div>
    </div>
    <div class="title-info-wrapper has-text-grey-dark">
      <h3 class="event-minimalist-title" :lang="event.language" dir="auto">
        <b-tag
          class="mr-2"
          type="is-warning"
          size="is-medium"
          v-if="event.draft"
          >{{ $t("Draft") }}</b-tag
        >
        {{ event.title }}
      </h3>
      <inline-address
        v-if="event.physicalAddress"
        class="event-subtitle"
        :physical-address="event.physicalAddress"
      />
      <div
        class="event-subtitle"
        v-else-if="event.options && event.options.isOnline"
      >
        <b-icon icon="video" />
        <span>{{ $t("Online") }}</span>
      </div>
      <div class="event-subtitle event-organizer" v-if="showOrganizer">
        <figure
          class="image is-24x24"
          v-if="organizer(event) && organizer(event).avatar"
        >
          <img class="is-rounded" :src="organizer(event).avatar.url" alt="" />
        </figure>
        <b-icon v-else icon="account-circle" />
        <span class="organizer-name">
          {{ organizerDisplayName(event) }}
        </span>
      </div>
      <p class="participant-metadata">
        <b-icon icon="account-multiple" />
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
import { IEvent, organizer, organizerDisplayName } from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { ParticipantRole } from "@/types/enums";
import RouteName from "../../router/name";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import InlineAddress from "@/components/Address/InlineAddress.vue";

@Component({
  components: {
    DateCalendarIcon,
    LazyImageWrapper,
    InlineAddress,
  },
})
export default class EventMinimalistCard extends Vue {
  @Prop({ required: true, type: Object }) event!: IEvent;
  @Prop({ required: false, type: Boolean, default: false })
  showOrganizer!: boolean;

  RouteName = RouteName;

  ParticipantRole = ParticipantRole;

  organizerDisplayName = organizerDisplayName;

  organizer = organizer;
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
@use "@/styles/_event-card";
@import "~bulma/sass/utilities/mixins.sass";
@import "@/variables.scss";

.event-minimalist-card-wrapper {
  display: grid;
  grid-gap: 5px 10px;
  grid-template-areas: "preview" "body";
  color: initial;

  @include desktop {
    grid-template-columns: 200px 3fr;
    grid-template-areas: "preview body";
  }

  .event-preview {
    & > div {
      position: relative;
      height: 120px;
      width: 100%;

      div.date-component {
        display: flex;
        position: absolute;
        bottom: 5px;
        left: 5px;
        z-index: 1;
      }
    }
  }

  .calendar-icon {
    @include margin-right(1rem);
  }

  .title-info-wrapper {
    flex: 2;

    .event-minimalist-title {
      padding-bottom: 5px;
      font-size: 18px;
      line-height: 24px;
      display: -webkit-box;
      -webkit-line-clamp: 3;
      -webkit-box-orient: vertical;
      overflow: hidden;
      font-weight: bold;
      color: $title-color;
    }

    ::v-deep .icon {
      vertical-align: middle;
    }
  }
}
</style>
