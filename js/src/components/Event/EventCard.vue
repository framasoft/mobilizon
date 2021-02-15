<template>
  <router-link
    class="card"
    :to="{ name: 'Event', params: { uuid: event.uuid } }"
  >
    <div class="card-image">
      <figure
        class="image is-16by9"
        :style="`background-image: url('${
          event.picture ? event.picture.url : '/img/mobilizon_default_card.png'
        }')`"
      >
        <div
          class="tag-container"
          v-if="event.tags || event.status !== EventStatus.CONFIRMED"
        >
          <b-tag type="is-info" v-if="event.status === EventStatus.TENTATIVE">
            {{ $t("Tentative") }}
          </b-tag>
          <b-tag type="is-danger" v-if="event.status === EventStatus.CANCELLED">
            {{ $t("Cancelled") }}
          </b-tag>
          <router-link
            :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
            v-for="tag in (event.tags || []).slice(0, 3)"
            :key="tag.slug"
          >
            <b-tag type="is-light">{{ tag.title }}</b-tag>
          </router-link>
        </div>
      </figure>
    </div>
    <div class="card-content">
      <div class="media">
        <div class="media-left">
          <date-calendar-icon
            v-if="!mergedOptions.hideDate"
            :date="event.beginsOn"
          />
        </div>
        <div class="media-content">
          <p class="event-title" :title="event.title">{{ event.title }}</p>
          <div
            class="event-subtitle"
            v-if="event.physicalAddress"
            :title="
              isDescriptionDifferentFromLocality
                ? `${event.physicalAddress.description}, ${event.physicalAddress.locality}`
                : event.physicalAddress.description
            "
          >
            <!--            <p>{{ $t('By @{username}', { username: actor.preferredUsername }) }}</p>-->
            <span v-if="isDescriptionDifferentFromLocality">
              {{ event.physicalAddress.description }},
              {{ event.physicalAddress.locality }}
            </span>
            <span v-else>
              {{ event.physicalAddress.description }}
            </span>
          </div>
        </div>
      </div>
    </div>
    <!--    <div class="date-and-title">-->
    <!--      <div class="date-component">-->
    <!--        <date-calendar-icon v-if="!mergedOptions.hideDate" :date="event.beginsOn" />-->
    <!--      </div>-->
    <!--      <div class="title-wrapper">-->
    <!--        <h4>{{ event.title }}</h4>-->
    <!--        <div class="organizer-place-wrapper has-text-grey">-->
    <!--          <span>{{ $t('By @{username}', { username: actor.preferredUsername }) }}</span>-->
    <!--           ·-->
    <!--          <span v-if="event.physicalAddress">-->
    <!--            {{ event.physicalAddress.description }}, {{ event.physicalAddress.locality }}-->
    <!--          </span>-->
    <!--        </div>-->
    <!--      </div>-->
    <!--    </div>-->
    <!--    <div v-if="!mergedOptions.hideDetails" class="details">-->
    <!--      <div v-if="event.participants.length > 0 &&-->
    <!--      mergedOptions.loggedPerson &&-->
    <!--      event.participants[0].actor.id === mergedOptions.loggedPerson.id">-->
    <!--        <b-tag type="is-info"><translate>Organizer</translate></b-tag>-->
    <!--      </div>-->
    <!--      <div v-else-if="event.participants.length === 1">-->
    <!--        <translate-->
    <!--                :translate-params="{name: event.participants[0].actor.preferredUsername}"-->
    <!--        >{name} organizes this event</translate>-->
    <!--      </div>-->
    <!--      <div v-else>-->
    <!--        <span v-for="participant in event.participants" :key="participant.actor.uuid">-->
    <!--          {{ participant.actor.preferredUsername }}-->
    <!--          <span v-if="participant.role === ParticipantRole.CREATOR">(organizer)</span>,-->
    <!--          &lt;!&ndash; <translate-->
    <!--            :translate-params="{name: participant.actor.preferredUsername}"-->
    <!--          >&nbsp;{name} is in,</translate>&ndash;&gt;-->
    <!--        </span>-->
    <!--      </div>-->
  </router-link>
</template>

<script lang="ts">
import { IEvent, IEventCardOptions } from "@/types/event.model";
import { Component, Prop, Vue } from "vue-property-decorator";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { Actor, Person } from "@/types/actor";
import { EventStatus, ParticipantRole } from "@/types/enums";
import RouteName from "../../router/name";

@Component({
  components: {
    DateCalendarIcon,
  },
})
export default class EventCard extends Vue {
  @Prop({ required: true }) event!: IEvent;

  @Prop({ required: false }) options!: IEventCardOptions;

  ParticipantRole = ParticipantRole;

  EventStatus = EventStatus;

  RouteName = RouteName;

  defaultOptions: IEventCardOptions = {
    hideDate: false,
    loggedPerson: false,
    hideDetails: false,
    organizerActor: null,
    memberofGroup: false,
  };

  get mergedOptions(): IEventCardOptions {
    return { ...this.defaultOptions, ...this.options };
  }

  get actor(): Actor {
    return Object.assign(
      new Person(),
      this.event.organizerActor || this.mergedOptions.organizerActor
    );
  }

  get isDescriptionDifferentFromLocality(): boolean {
    return (
      this.event?.physicalAddress?.description !==
        this.event?.physicalAddress?.locality &&
      this.event?.physicalAddress?.description !== undefined
    );
  }
}
</script>

<style lang="scss" scoped>
a.card {
  display: block;
  background: $secondary;
  color: #3c376e;

  &:hover {
    // box-shadow: 0 0 5px 0 rgba(0, 0, 0, 1);
    transform: scale(1.01, 1.01);
    &:after {
      opacity: 1;
    }
  }

  border-radius: 5px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  transition: all 0.6s cubic-bezier(0.165, 0.84, 0.44, 1);

  &:after {
    content: "";
    border-radius: 5px;
    position: absolute;
    z-index: -1;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
    opacity: 0;
    transition: all 0.6s cubic-bezier(0.165, 0.84, 0.44, 1);
  }

  div.tag-container {
    position: absolute;
    top: 10px;
    right: 0;
    margin-right: -3px;
    z-index: 10;
    max-width: 40%;

    a {
      text-decoration: none;

      span.tag {
        margin: 5px auto;
        text-overflow: ellipsis;
        overflow: hidden;
        display: block;
        font-size: 0.9em;
        line-height: 1.75em;
        background-color: #e6e4f4;
        color: #3c376e;
      }
    }
  }

  div.card-image {
    background: $secondary;

    figure.image {
      background-size: cover;
      background-position: center;
    }
  }

  .card-content {
    padding: 0.5rem;

    .event-title {
      font-size: 1.2rem;
      line-height: 1.25rem;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
      min-height: 2.4rem;
      font-weight: bold;
    }

    .event-subtitle {
      font-size: 0.85rem;
      display: inline-flex;
      flex-wrap: wrap;
      color: #3c376e;

      span {
        width: 14rem;
        display: block;
        overflow: hidden;

        flex-grow: 1;

        text-overflow: ellipsis;
        white-space: nowrap;
      }
    }
  }
}
</style>
