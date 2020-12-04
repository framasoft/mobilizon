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
        <b-tooltip :label="$t('Click for more information')">
          <span
            class="is-clickable"
            @click="isAnonymousParticipationModalOpen = true"
          >
            <b-icon size="is-small" icon="information-outline" />
          </span>
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
    <b-modal
      :active.sync="isAnonymousParticipationModalOpen"
      has-modal-card
      ref="anonymous-participation-modal"
    >
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">
            {{ $t("About anonymous participation") }}
          </p>
        </header>

        <section class="modal-card-body">
          <b-notification
            type="is-primary"
            :closable="false"
            v-if="event.joinOptions === EventJoinOptions.RESTRICTED"
          >
            {{
              $t(
                "As the event organizer has chosen to manually validate participation requests, your participation will be really confirmed only once you receive an email stating it's being accepted."
              )
            }}
          </b-notification>
          <p>
            {{
              $t(
                "Your participation status is saved only on this device and will be deleted one month after the event's passed."
              )
            }}
          </p>
          <p v-if="isSecureContext">
            {{
              $t(
                "You may clear all participation information for this device with the buttons below."
              )
            }}
          </p>
          <div class="buttons" v-if="isSecureContext">
            <b-button
              type="is-danger is-outlined"
              @click="clearEventParticipationData"
            >
              {{ $t("Clear participation data for this event") }}
            </b-button>
            <b-button type="is-danger" @click="clearAllParticipationData">
              {{ $t("Clear participation data for all events") }}
            </b-button>
          </div>
        </section>
      </div>
    </b-modal>
  </div>
</template>
<script lang="ts">
import { EventJoinOptions, EventStatus, ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "@/router/name";
import { IEvent } from "@/types/event.model";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { IConfig } from "@/types/config.model";
import { CONFIG } from "@/graphql/config";
import {
  removeAllAnonymousParticipations,
  removeAnonymousParticipation,
} from "@/services/AnonymousParticipationStorage";
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

  EventJoinOptions = EventJoinOptions;

  isAnonymousParticipationModalOpen = false;

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

  // eslint-disable-next-line class-methods-use-this
  get isSecureContext(): boolean {
    return window.isSecureContext;
  }

  async clearEventParticipationData(): Promise<void> {
    await removeAnonymousParticipation(this.event.uuid);
    window.location.reload();
  }

  // eslint-disable-next-line class-methods-use-this
  clearAllParticipationData(): void {
    removeAllAnonymousParticipations();
    window.location.reload();
  }
}
</script>
