<template>
  <div>
    <div
      class="event-participation has-text-right"
      v-if="isEventNotAlreadyPassed"
    >
      <participation-button
        v-if="shouldShowParticipationButton"
        :participation="participation"
        :event="event"
        :current-actor="currentActor"
        @join-event="(actor) => $emit('join-event', actor)"
        @join-modal="$emit('join-modal')"
        @join-event-with-confirmation="
          (actor) => $emit('join-event-with-confirmation', actor)
        "
        @confirm-leave="$emit('confirm-leave')"
      />
      <b-button
        type="is-text"
        v-if="!actorIsParticipant && anonymousParticipation !== null"
        @click="$emit('cancel-anonymous-participation')"
        >{{ $t("Cancel anonymous participation") }}</b-button
      >
      <small v-if="!actorIsParticipant && anonymousParticipation">
        {{ $t("You are participating in this event anonymously") }}
        <b-tooltip
          :label="
            $t(
              'This information is saved only on your computer. Click for details'
            )
          "
        >
          <router-link :to="{ name: RouteName.TERMS }">
            <b-icon size="is-small" icon="help-circle-outline" />
          </router-link>
        </b-tooltip>
      </small>
      <small
        v-else-if="!actorIsParticipant && anonymousParticipation === false"
      >
        {{
          $t(
            "You are participating in this event anonymously but didn't confirm participation"
          )
        }}
        <b-tooltip
          :label="
            $t(
              'This information is saved only on your computer. Click for details'
            )
          "
        >
          <router-link :to="{ name: RouteName.TERMS }">
            <b-icon size="is-small" icon="help-circle-outline" />
          </router-link>
        </b-tooltip>
      </small>
    </div>
    <div v-else>
      <button class="button is-primary" type="button" slot="trigger" disabled>
        <template>
          <span>{{ $t("Event already passed") }}</span>
        </template>
        <b-icon icon="menu-down" />
      </button>
    </div>
  </div>
</template>
<script lang="ts">
import { EventStatus, ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "@/router/name";
import { IEvent } from "@/types/event.model";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { IConfig } from "@/types/config.model";
import { CONFIG } from "@/graphql/config";
import ParticipationButton from "../Event/ParticipationButton.vue";

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    config: CONFIG,
  },
  components: {
    ParticipationButton,
  },
})
export default class ParticipationSection extends Vue {
  @Prop({ required: true }) participation!: IParticipant;

  @Prop({ required: true }) event!: IEvent;

  @Prop({ required: true, default: null }) anonymousParticipation!:
    | boolean
    | null;

  currentActor!: IPerson;

  config!: IConfig;

  RouteName = RouteName;

  get actorIsParticipant(): boolean {
    if (this.actorIsOrganizer) return true;

    return (
      this.participation &&
      this.participation.role === ParticipantRole.PARTICIPANT
    );
  }

  get actorIsOrganizer(): boolean {
    return (
      this.participation && this.participation.role === ParticipantRole.CREATOR
    );
  }

  get shouldShowParticipationButton(): boolean {
    // If we have an anonymous participation, don't show the participation button
    if (
      this.config &&
      this.config.anonymous.participation.allowed &&
      this.anonymousParticipation
    ) {
      return false;
    }

    // So that people can cancel their participation
    if (this.actorIsParticipant) return true;

    // You can participate to draft or cancelled events
    if (this.event.draft || this.event.status === EventStatus.CANCELLED)
      return false;

    // Organizer can't participate
    if (this.actorIsOrganizer) return false;

    // If capacity is OK
    if (this.eventCapacityOK) return true;

    // Else
    return false;
  }

  get eventCapacityOK(): boolean {
    if (this.event.draft) return true;
    if (!this.event.options.maximumAttendeeCapacity) return true;
    return (
      this.event.options.maximumAttendeeCapacity >
      this.event.participantStats.participant
    );
  }

  get isEventNotAlreadyPassed(): boolean {
    return new Date(this.endDate) > new Date();
  }

  get endDate(): Date {
    return this.event.endsOn !== null && this.event.endsOn > this.event.beginsOn
      ? this.event.endsOn
      : this.event.beginsOn;
  }
}
</script>
