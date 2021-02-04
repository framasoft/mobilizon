<template>
  <div class="container">
    <transition appear name="fade" mode="out-in">
      <div>
        <div
          class="header-picture"
          v-if="event.picture"
          :style="`background-image: url('${event.picture.url}')`"
        />
        <div class="header-picture-default" v-else />
        <section class="section intro">
          <div class="columns">
            <div class="column is-1-tablet">
              <date-calendar-icon :date="event.beginsOn" />
            </div>
            <div class="column">
              <h1 class="title" style="margin: 0">{{ event.title }}</h1>
              <div class="organizer">
                <span v-if="event.organizerActor && !event.attributedTo">
                  <popover-actor-card
                    :actor="event.organizerActor"
                    :inline="true"
                  >
                    <span>
                      {{
                        $t("By @{username}", {
                          username: usernameWithDomain(event.organizerActor),
                        })
                      }}
                    </span>
                  </popover-actor-card>
                </span>
                <span
                  v-else-if="
                    event.attributedTo &&
                    event.options.hideOrganizerWhenGroupEvent
                  "
                >
                  <popover-actor-card
                    :actor="event.attributedTo"
                    :inline="true"
                  >
                    {{
                      $t("By @{group}", {
                        group: usernameWithDomain(event.attributedTo),
                      })
                    }}
                  </popover-actor-card>
                </span>
                <span v-else-if="event.organizerActor && event.attributedTo">
                  <i18n path="By {group}">
                    <popover-actor-card
                      :actor="event.attributedTo"
                      slot="group"
                      :inline="true"
                    >
                      <router-link
                        :to="{
                          name: RouteName.GROUP,
                          params: {
                            preferredUsername: usernameWithDomain(
                              event.attributedTo
                            ),
                          },
                        }"
                      >
                        {{
                          $t("@{group}", {
                            group: usernameWithDomain(event.attributedTo),
                          })
                        }}
                      </router-link>
                    </popover-actor-card>
                  </i18n>
                </span>
              </div>
              <p class="tags" v-if="event.tags && event.tags.length > 0">
                <router-link
                  v-for="tag in event.tags"
                  :key="tag.title"
                  :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
                >
                  <tag>{{ tag.title }}</tag>
                </router-link>
              </p>
              <b-tag type="is-warning" size="is-medium" v-if="event.draft"
                >{{ $t("Draft") }}
              </b-tag>
              <span
                class="event-status"
                v-if="event.status !== EventStatus.CONFIRMED"
              >
                <b-tag
                  type="is-warning"
                  v-if="event.status === EventStatus.TENTATIVE"
                  >{{ $t("Event to be confirmed") }}</b-tag
                >
                <b-tag
                  type="is-danger"
                  v-if="event.status === EventStatus.CANCELLED"
                  >{{ $t("Event cancelled") }}</b-tag
                >
              </span>
            </div>
            <div class="column is-3-tablet">
              <participation-section
                :participation="participations[0]"
                :event="event"
                :anonymousParticipation="anonymousParticipation"
                @join-event="joinEvent"
                @join-modal="isJoinModalActive = true"
                @join-event-with-confirmation="joinEventWithConfirmation"
                @confirm-leave="confirmLeave"
                @cancel-anonymous-participation="cancelAnonymousParticipation"
              />
              <div class="has-text-right">
                <template class="visibility" v-if="!event.draft">
                  <p v-if="event.visibility === EventVisibility.PUBLIC">
                    {{ $t("Public event") }}
                    <b-icon icon="earth" />
                  </p>
                  <p v-if="event.visibility === EventVisibility.UNLISTED">
                    {{ $t("Private event") }}
                    <b-icon icon="link" />
                  </p>
                </template>
                <template v-if="!event.local && organizer">
                  <a :href="event.url">
                    <tag>{{ organizer.domain }}</tag>
                  </a>
                </template>
                <p>
                  <router-link
                    class="participations-link"
                    v-if="actorIsOrganizer && event.draft === false"
                    :to="{
                      name: RouteName.PARTICIPATIONS,
                      params: { eventId: event.uuid },
                    }"
                  >
                    <!-- We retire one because of the event creator who is a participant -->
                    <span v-if="event.options.maximumAttendeeCapacity">
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
                        $tc(
                          "No one is going to this event",
                          event.participantStats.participant,
                          {
                            going: event.participantStats.participant,
                          }
                        )
                      }}
                    </span>
                  </router-link>
                  <span v-else>
                    <span v-if="event.options.maximumAttendeeCapacity">
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
                        $tc(
                          "No one is going to this event",
                          event.participantStats.participant,
                          {
                            going: event.participantStats.participant,
                          }
                        )
                      }}
                    </span>
                  </span>
                  <b-tooltip
                    type="is-dark"
                    v-if="!event.local"
                    :label="
                      $t(
                        'The actual number of participants may differ, as this event is hosted on another instance.'
                      )
                    "
                  >
                    <b-icon size="is-small" icon="help-circle-outline" />
                  </b-tooltip>
                  <b-icon icon="ticket-confirmation-outline" />
                </p>
                <b-dropdown position="is-bottom-left" aria-role="list">
                  <b-button
                    slot="trigger"
                    role="button"
                    icon-right="dots-horizontal"
                  >
                    {{ $t("Actions") }}
                  </b-button>
                  <b-dropdown-item
                    aria-role="listitem"
                    has-link
                    v-if="actorIsOrganizer || event.draft"
                  >
                    <router-link
                      :to="{
                        name: RouteName.EDIT_EVENT,
                        params: { eventId: event.uuid },
                      }"
                    >
                      {{ $t("Edit") }}
                      <b-icon icon="pencil" />
                    </router-link>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    has-link
                    v-if="actorIsOrganizer || event.draft"
                  >
                    <router-link
                      :to="{
                        name: RouteName.DUPLICATE_EVENT,
                        params: { eventId: event.uuid },
                      }"
                    >
                      {{ $t("Duplicate") }}
                      <b-icon icon="content-duplicate" />
                    </router-link>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    v-if="actorIsOrganizer || event.draft"
                    @click="openDeleteEventModalWrapper"
                  >
                    {{ $t("Delete") }}
                    <b-icon icon="delete" />
                  </b-dropdown-item>

                  <hr
                    class="dropdown-divider"
                    aria-role="menuitem"
                    v-if="actorIsOrganizer || event.draft"
                  />
                  <b-dropdown-item
                    aria-role="listitem"
                    v-if="!event.draft"
                    @click="triggerShare()"
                  >
                    <span>
                      {{ $t("Share this event") }}
                      <b-icon icon="share" />
                    </span>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    @click="downloadIcsEvent()"
                    v-if="!event.draft"
                  >
                    <span>
                      {{ $t("Add to my calendar") }}
                      <b-icon icon="calendar-plus" />
                    </span>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    v-if="ableToReport"
                    @click="isReportModalActive = true"
                  >
                    <span>
                      {{ $t("Report") }}
                      <b-icon icon="flag" />
                    </span>
                  </b-dropdown-item>
                </b-dropdown>
              </div>
            </div>
          </div>
        </section>
        <div class="event-description-wrapper">
          <aside class="event-metadata">
            <div class="sticky">
              <event-metadata-block
                :title="$t('Location')"
                :icon="
                  physicalAddress
                    ? physicalAddress.poiInfos.poiIcon.icon
                    : 'earth'
                "
              >
                <div class="address-wrapper">
                  <span v-if="!physicalAddress">{{
                    $t("No address defined")
                  }}</span>
                  <div class="address" v-if="physicalAddress">
                    <div>
                      <address>
                        <p
                          class="addressDescription"
                          :title="physicalAddress.poiInfos.name"
                        >
                          {{ physicalAddress.poiInfos.name }}
                        </p>
                        <p>{{ physicalAddress.poiInfos.alternativeName }}</p>
                      </address>
                    </div>
                    <span
                      class="map-show-button"
                      @click="showMap = !showMap"
                      v-if="physicalAddress.geom"
                      >{{ $t("Show map") }}</span
                    >
                  </div>
                </div>
              </event-metadata-block>
              <event-metadata-block
                :title="$t('Date and time')"
                icon="calendar"
              >
                <event-full-date
                  :beginsOn="event.beginsOn"
                  :show-start-time="event.options.showStartTime"
                  :show-end-time="event.options.showEndTime"
                  :endsOn="event.endsOn"
                />
              </event-metadata-block>
              <event-metadata-block :title="$t('Organized by')">
                <popover-actor-card
                  :actor="event.organizerActor"
                  v-if="!event.attributedTo"
                >
                  <actor-card :actor="event.organizerActor" />
                </popover-actor-card>
                <router-link
                  v-if="event.attributedTo"
                  :to="{
                    name: RouteName.GROUP,
                    params: {
                      preferredUsername: usernameWithDomain(event.attributedTo),
                    },
                  }"
                >
                  <popover-actor-card
                    :actor="event.attributedTo"
                    v-if="
                      !event.attributedTo ||
                      !event.options.hideOrganizerWhenGroupEvent
                    "
                  >
                    <actor-card :actor="event.attributedTo" />
                  </popover-actor-card>
                </router-link>

                <popover-actor-card
                  :actor="contact"
                  v-for="contact in event.contacts"
                  :key="contact.id"
                >
                  <actor-card :actor="contact" />
                </popover-actor-card>
              </event-metadata-block>
              <event-metadata-block
                v-if="event.onlineAddress && urlToHostname(event.onlineAddress)"
                icon="link"
                :title="$t('Website')"
              >
                <a
                  target="_blank"
                  rel="noopener noreferrer"
                  :href="event.onlineAddress"
                  :title="
                    $t('View page on {hostname} (in a new window)', {
                      hostname: urlToHostname(event.onlineAddress),
                    })
                  "
                  >{{ urlToHostname(event.onlineAddress) }}</a
                >
              </event-metadata-block>
            </div>
          </aside>
          <div class="event-description-comments">
            <section class="event-description">
              <subtitle>{{ $t("About this event") }}</subtitle>
              <p v-if="!event.description">
                {{ $t("The event organizer didn't add any description.") }}
              </p>
              <div v-else>
                <div
                  class="description-content"
                  ref="eventDescriptionElement"
                  v-html="event.description"
                />
              </div>
            </section>
            <section class="comments" ref="commentsObserver">
              <a href="#comments">
                <subtitle id="comments">{{ $t("Comments") }}</subtitle>
              </a>
              <comment-tree v-if="loadComments" :event="event" />
            </section>
          </div>
        </div>
        <section
          class="more-events section"
          v-if="event.relatedEvents.length > 0"
        >
          <h3 class="title has-text-centered">
            {{ $t("These events may interest you") }}
          </h3>
          <div class="columns">
            <div
              class="column is-one-third-desktop"
              v-for="relatedEvent in event.relatedEvents"
              :key="relatedEvent.uuid"
            >
              <EventCard :event="relatedEvent" />
            </div>
          </div>
        </section>
        <b-modal
          :active.sync="isReportModalActive"
          has-modal-card
          ref="reportModal"
        >
          <report-modal
            :on-confirm="reportEvent"
            :title="$t('Report this event')"
            :outside-domain="organizerDomain"
            @close="$refs.reportModal.close()"
          />
        </b-modal>
        <b-modal
          :active.sync="isShareModalActive"
          has-modal-card
          ref="shareModal"
        >
          <share-event-modal
            :event="event"
            :eventCapacityOK="eventCapacityOK"
          />
        </b-modal>
        <b-modal
          :active.sync="isJoinModalActive"
          has-modal-card
          ref="participationModal"
        >
          <identity-picker v-model="identity">
            <template v-slot:footer>
              <footer class="modal-card-foot">
                <button
                  class="button"
                  ref="cancelButton"
                  @click="isJoinModalActive = false"
                >
                  {{ $t("Cancel") }}
                </button>
                <button
                  class="button is-primary"
                  ref="confirmButton"
                  @click="
                    event.joinOptions === EventJoinOptions.RESTRICTED
                      ? joinEventWithConfirmation(identity)
                      : joinEvent(identity)
                  "
                >
                  {{ $t("Confirm my particpation") }}
                </button>
              </footer>
            </template>
          </identity-picker>
        </b-modal>
        <b-modal
          :active.sync="isJoinConfirmationModalActive"
          has-modal-card
          ref="joinConfirmationModal"
        >
          <div class="modal-card">
            <header class="modal-card-head">
              <p class="modal-card-title">
                {{ $t("Participation confirmation") }}
              </p>
            </header>

            <section class="modal-card-body">
              <p>
                {{
                  $t(
                    "The event organiser has chosen to validate manually participations. Do you want to add a little note to explain why you want to participate to this event?"
                  )
                }}
              </p>
              <form
                @submit.prevent="
                  joinEvent(actorForConfirmation, messageForConfirmation)
                "
              >
                <b-field :label="$t('Message')">
                  <b-input
                    type="textarea"
                    size="is-medium"
                    v-model="messageForConfirmation"
                    minlength="10"
                  ></b-input>
                </b-field>
                <div class="buttons">
                  <b-button
                    native-type="button"
                    class="button"
                    ref="cancelButton"
                    @click="isJoinConfirmationModalActive = false"
                    >{{ $t("Cancel") }}
                  </b-button>
                  <b-button type="is-primary" native-type="submit">
                    {{ $t("Confirm my participation") }}
                  </b-button>
                </div>
              </form>
            </section>
          </div>
        </b-modal>
        <b-modal
          class="map-modal"
          v-if="physicalAddress && physicalAddress.geom"
          :active.sync="showMap"
          has-modal-card
          full-screen
        >
          <div class="modal-card">
            <header class="modal-card-head">
              <button type="button" class="delete" @click="showMap = false" />
            </header>
            <div class="modal-card-body">
              <section class="map">
                <map-leaflet
                  :coords="physicalAddress.geom"
                  :marker="{
                    text: physicalAddress.fullName,
                    icon: physicalAddress.poiInfos.poiIcon.icon,
                  }"
                />
              </section>
              <section class="columns is-centered map-footer">
                <div class="column is-half has-text-centered">
                  <p class="address">
                    <i class="mdi mdi-map-marker"></i>
                    {{ physicalAddress.fullName }}
                  </p>
                  <p class="getting-there">{{ $t("Getting there") }}</p>
                  <div
                    class="buttons"
                    v-if="
                      addressLinkToRouteByCar ||
                      addressLinkToRouteByBike ||
                      addressLinkToRouteByFeet
                    "
                  >
                    <a
                      class="button"
                      target="_blank"
                      v-if="addressLinkToRouteByFeet"
                      :href="addressLinkToRouteByFeet"
                    >
                      <i class="mdi mdi-walk"></i
                    ></a>
                    <a
                      class="button"
                      target="_blank"
                      v-if="addressLinkToRouteByBike"
                      :href="addressLinkToRouteByBike"
                    >
                      <i class="mdi mdi-bike"></i
                    ></a>
                    <a
                      class="button"
                      target="_blank"
                      v-if="addressLinkToRouteByTransit"
                      :href="addressLinkToRouteByTransit"
                    >
                      <i class="mdi mdi-bus"></i
                    ></a>
                    <a
                      class="button"
                      target="_blank"
                      v-if="addressLinkToRouteByCar"
                      :href="addressLinkToRouteByCar"
                    >
                      <i class="mdi mdi-car"></i>
                    </a>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </b-modal>
      </div>
    </transition>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Watch } from "vue-property-decorator";
import BIcon from "buefy/src/components/icon/Icon.vue";
import {
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  ParticipantRole,
  RoutingTransportationType,
  RoutingType,
} from "@/types/enums";
import {
  EVENT_PERSON_PARTICIPATION,
  EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
  FETCH_EVENT,
  JOIN_EVENT,
} from "../../graphql/event";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { EventModel, IEvent } from "../../types/event.model";
import { IActor, IPerson, Person, usernameWithDomain } from "../../types/actor";
import { GRAPHQL_API_ENDPOINT } from "../../api/_entrypoint";
import DateCalendarIcon from "../../components/Event/DateCalendarIcon.vue";
import EventCard from "../../components/Event/EventCard.vue";
import EventFullDate from "../../components/Event/EventFullDate.vue";
import ReportModal from "../../components/Report/ReportModal.vue";
import { IReport } from "../../types/report.model";
import { CREATE_REPORT } from "../../graphql/report";
import EventMixin from "../../mixins/event";
import IdentityPicker from "../Account/IdentityPicker.vue";
import ParticipationSection from "../../components/Participation/ParticipationSection.vue";
import RouteName from "../../router/name";
import { Address } from "../../types/address.model";
import CommentTree from "../../components/Comment/CommentTree.vue";
import "intersection-observer";
import { CONFIG } from "../../graphql/config";
import {
  AnonymousParticipationNotFoundError,
  getLeaveTokenForParticipation,
  isParticipatingInThisEvent,
  removeAnonymousParticipation,
} from "../../services/AnonymousParticipationStorage";
import { IConfig } from "../../types/config.model";
import Subtitle from "../../components/Utils/Subtitle.vue";
import Tag from "../../components/Tag.vue";
import EventMetadataBlock from "../../components/Event/EventMetadataBlock.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import PopoverActorCard from "../../components/Account/PopoverActorCard.vue";
import { IParticipant } from "../../types/participant.model";

// noinspection TypeScriptValidateTypes
@Component({
  components: {
    EventMetadataBlock,
    Subtitle,
    EventFullDate,
    EventCard,
    BIcon,
    DateCalendarIcon,
    ReportModal,
    IdentityPicker,
    ParticipationSection,
    CommentTree,
    Tag,
    ActorCard,
    PopoverActorCard,
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "../../components/Map.vue"),
    ShareEventModal: () =>
      import(
        /* webpackChunkName: "shareEventModal" */ "../../components/Event/ShareEventModal.vue"
      ),
  },
  apollo: {
    event: {
      query: FETCH_EVENT,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          uuid: this.uuid,
        };
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    participations: {
      query: EVENT_PERSON_PARTICIPATION,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          eventId: this.event.id,
          actorId: this.currentActor.id,
        };
      },
      subscribeToMore: {
        document: EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
        variables() {
          return {
            eventId: this.event.id,
            actorId: this.currentActor.id,
          };
        },
      },
      update: (data) => {
        if (data && data.person) return data.person.participations.elements;
        return [];
      },
      skip() {
        return (
          !this.currentActor ||
          !this.event ||
          !this.event.id ||
          !this.currentActor.id
        );
      },
    },
    config: CONFIG,
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.eventTitle,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
      meta: [
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        { name: "description", content: this.eventDescription },
      ],
    };
  },
})
export default class Event extends EventMixin {
  @Prop({ type: String, required: true }) uuid!: string;

  event: IEvent = new EventModel();

  currentActor!: IPerson;

  identity: IPerson = new Person();

  config!: IConfig;

  participations: IParticipant[] = [];

  oldParticipationRole!: string;

  showMap = false;

  isReportModalActive = false;

  isShareModalActive = false;

  isJoinModalActive = false;

  isJoinConfirmationModalActive = false;

  EventVisibility = EventVisibility;

  EventStatus = EventStatus;

  EventJoinOptions = EventJoinOptions;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  observer!: IntersectionObserver;

  loadComments = false;

  anonymousParticipation: boolean | null = null;

  actorForConfirmation!: IPerson;

  messageForConfirmation = "";

  RoutingParamType = {
    [RoutingType.OPENSTREETMAP]: {
      [RoutingTransportationType.FOOT]: "engine=fossgis_osrm_foot",
      [RoutingTransportationType.BIKE]: "engine=fossgis_osrm_bike",
      [RoutingTransportationType.TRANSIT]: null,
      [RoutingTransportationType.CAR]: "engine=fossgis_osrm_car",
    },
    [RoutingType.GOOGLE_MAPS]: {
      [RoutingTransportationType.FOOT]: "dirflg=w",
      [RoutingTransportationType.BIKE]: "dirflg=b",
      [RoutingTransportationType.TRANSIT]: "dirflg=r",
      [RoutingTransportationType.CAR]: "driving",
    },
  };

  makeNavigationPath(
    transportationType: RoutingTransportationType
  ): string | undefined {
    const geometry = this.physicalAddress?.geom;
    if (geometry) {
      const routingType = this.config.maps.routing.type;
      /**
       * build urls to routing map
       */
      if (!this.RoutingParamType[routingType][transportationType]) {
        return;
      }

      const urlGeometry = geometry.split(";").reverse().join(",");

      switch (routingType) {
        case RoutingType.GOOGLE_MAPS:
          return `https://maps.google.com/?saddr=Current+Location&daddr=${urlGeometry}&${this.RoutingParamType[routingType][transportationType]}`;
        case RoutingType.OPENSTREETMAP:
        default: {
          const bboxX = geometry.split(";").reverse()[0];
          const bboxY = geometry.split(";").reverse()[1];
          return `https://www.openstreetmap.org/directions?from=&to=${urlGeometry}&${this.RoutingParamType[routingType][transportationType]}#map=14/${bboxX}/${bboxY}`;
        }
      }
    }
  }

  get addressLinkToRouteByCar(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.CAR);
  }

  get addressLinkToRouteByBike(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.BIKE);
  }

  get addressLinkToRouteByFeet(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.FOOT);
  }

  get addressLinkToRouteByTransit(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.TRANSIT);
  }

  get eventTitle(): undefined | string {
    if (!this.event) return undefined;
    return this.event.title;
  }

  get eventDescription(): undefined | string {
    if (!this.event) return undefined;
    return this.event.description;
  }

  async mounted(): Promise<void> {
    this.identity = this.currentActor;
    if (this.$route.hash.includes("#comment-")) {
      this.loadComments = true;
    }

    try {
      if (window.isSecureContext) {
        this.anonymousParticipation = await this.anonymousParticipationConfirmed();
      }
    } catch (e) {
      if (e instanceof AnonymousParticipationNotFoundError) {
        this.anonymousParticipation = null;
      } else {
        console.error(e);
      }
    }

    this.observer = new IntersectionObserver(
      (entries) => {
        // eslint-disable-next-line no-restricted-syntax
        for (const entry of entries) {
          if (entry) {
            this.loadComments = entry.isIntersecting || this.loadComments;
          }
        }
      },
      {
        rootMargin: "-50px 0px -50px",
      }
    );
    this.observer.observe(this.$refs.commentsObserver as Element);

    this.$watch("eventDescription", (eventDescription) => {
      if (!eventDescription) return;
      const eventDescriptionElement = this.$refs
        .eventDescriptionElement as HTMLElement;

      eventDescriptionElement.addEventListener("click", ($event) => {
        // TODO: Find the right type for target
        let { target }: { target: any } = $event;
        while (target && target.tagName !== "A") target = target.parentNode;
        // handle only links that occur inside the component and do not reference external resources
        if (target && target.matches(".hashtag") && target.href) {
          // some sanity checks taken from vue-router:
          // https://github.com/vuejs/vue-router/blob/dev/src/components/link.js#L106
          const {
            altKey,
            ctrlKey,
            metaKey,
            shiftKey,
            button,
            defaultPrevented,
          } = $event;
          // don't handle with control keys
          if (metaKey || altKey || ctrlKey || shiftKey) return;
          // don't handle when preventDefault called
          if (defaultPrevented) return;
          // don't handle right clicks
          if (button !== undefined && button !== 0) return;
          // don't handle if `target="_blank"`
          if (target && target.getAttribute) {
            const linkTarget = target.getAttribute("target");
            if (/\b_blank\b/i.test(linkTarget)) return;
          }
          // don't handle same page links/anchors
          const url = new URL(target.href);
          const to = url.pathname;
          if (window.location.pathname !== to && $event.preventDefault) {
            $event.preventDefault();
            this.$router.push(to);
          }
        }
      });
    });

    this.$on("event-deleted", () => {
      return this.$router.push({ name: RouteName.HOME });
    });
  }

  /**
   * Delete the event, then redirect to home.
   */
  async openDeleteEventModalWrapper(): Promise<void> {
    await this.openDeleteEventModal(this.event);
  }

  async reportEvent(content: string, forward: boolean): Promise<void> {
    this.isReportModalActive = false;
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.$refs.reportModal.close();
    if (!this.organizer) return;
    const eventTitle = this.event.title;

    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          eventId: this.event.id,
          reportedId: this.organizer ? this.organizer.id : null,
          content,
          forward,
        },
      });
      this.$notifier.success(
        this.$t("Event {eventTitle} reported", { eventTitle }) as string
      );
    } catch (error) {
      console.error(error);
    }
  }

  joinEventWithConfirmation(actor: IPerson): void {
    this.isJoinConfirmationModalActive = true;
    this.actorForConfirmation = actor;
  }

  async joinEvent(
    identity: IPerson,
    message: string | null = null
  ): Promise<void> {
    this.isJoinConfirmationModalActive = false;
    this.isJoinModalActive = false;
    try {
      const { data: mutationData } = await this.$apollo.mutate<{
        joinEvent: IParticipant;
      }>({
        mutation: JOIN_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: identity.id,
          message,
        },
        update: (store, { data }) => {
          if (data == null) return;

          const participationCachedData = store.readQuery<{ person: IPerson }>({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: identity.id },
          });
          if (participationCachedData == null) return;
          const { person } = participationCachedData;
          if (person === null) {
            console.error(
              "Cannot update participation cache, because of null value."
            );
            return;
          }
          person.participations.elements.push(data.joinEvent);
          person.participations.total += 1;
          store.writeQuery({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: identity.id },
            data: { person },
          });

          const cachedData = store.readQuery<{ event: IEvent }>({
            query: FETCH_EVENT,
            variables: { uuid: this.event.uuid },
          });
          if (cachedData == null) return;
          const { event } = cachedData;
          if (event === null) {
            console.error(
              "Cannot update event participant cache, because of null value."
            );
            return;
          }

          if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
            event.participantStats.notApproved += 1;
          } else {
            event.participantStats.going += 1;
            event.participantStats.participant += 1;
          }

          store.writeQuery({
            query: FETCH_EVENT,
            variables: { uuid: this.uuid },
            data: { event },
          });
        },
      });
      if (mutationData) {
        if (mutationData.joinEvent.role === ParticipantRole.NOT_APPROVED) {
          this.participationRequestedMessage();
        } else {
          this.participationConfirmedMessage();
        }
      }
    } catch (error) {
      console.error(error);
    }
  }

  confirmLeave(): void {
    this.$buefy.dialog.confirm({
      title: this.$t('Leaving event "{title}"', {
        title: this.event.title,
      }) as string,
      message: this.$t(
        'Are you sure you want to cancel your participation at event "{title}"?',
        {
          title: this.event.title,
        }
      ) as string,
      confirmText: this.$t("Leave event") as string,
      cancelText: this.$t("Cancel") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => {
        if (this.currentActor.id) {
          this.leaveEvent(this.event, this.currentActor.id);
        }
      },
    });
  }

  @Watch("participations")
  watchParticipations(): void {
    if (this.participations.length > 0) {
      if (
        this.oldParticipationRole &&
        this.participations[0].role !== ParticipantRole.NOT_APPROVED &&
        this.oldParticipationRole !== this.participations[0].role
      ) {
        switch (this.participations[0].role) {
          case ParticipantRole.PARTICIPANT:
            this.participationConfirmedMessage();
            break;
          case ParticipantRole.REJECTED:
            this.participationRejectedMessage();
            break;
          default:
            this.participationChangedMessage();
            break;
        }
      }
      this.oldParticipationRole = this.participations[0].role;
    }
  }

  private participationConfirmedMessage() {
    this.$notifier.success(
      this.$t("Your participation has been confirmed") as string
    );
  }

  private participationRequestedMessage() {
    this.$notifier.success(
      this.$t("Your participation has been requested") as string
    );
  }

  private participationRejectedMessage() {
    this.$notifier.error(
      this.$t("Your participation has been rejected") as string
    );
  }

  private participationChangedMessage() {
    this.$notifier.info(
      this.$t("Your participation status has been changed") as string
    );
  }

  async downloadIcsEvent(): Promise<void> {
    const data = await (
      await fetch(`${GRAPHQL_API_ENDPOINT}/events/${this.uuid}/export/ics`)
    ).text();
    const blob = new Blob([data], { type: "text/calendar" });
    const link = document.createElement("a");
    link.href = window.URL.createObjectURL(blob);
    link.download = `${this.event.title}.ics`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  triggerShare(): void {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-start
    if (navigator.share) {
      navigator
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        .share({
          title: this.event.title,
          url: this.event.url,
        })
        .then(() => console.log("Successful share"))
        .catch((error: any) => console.log("Error sharing", error));
    } else {
      this.isShareModalActive = true;
      // send popup
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-end
  }

  handleErrors(errors: any[]): void {
    if (
      errors.some((error) => error.status_code === 404) ||
      errors.some(({ message }) => message.includes("has invalid value $uuid"))
    ) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  get actorIsParticipant(): boolean {
    if (this.actorIsOrganizer) return true;

    return (
      this.participations.length > 0 &&
      this.participations[0].role === ParticipantRole.PARTICIPANT
    );
  }

  get actorIsOrganizer(): boolean {
    return (
      this.participations.length > 0 &&
      this.participations[0].role === ParticipantRole.CREATOR
    );
  }

  get endDate(): Date {
    return this.event.endsOn !== null && this.event.endsOn > this.event.beginsOn
      ? this.event.endsOn
      : this.event.beginsOn;
  }

  get eventCapacityOK(): boolean {
    if (this.event.draft) return true;
    if (!this.event.options.maximumAttendeeCapacity) return true;
    return (
      this.event.options.maximumAttendeeCapacity >
      this.event.participantStats.participant
    );
  }

  get numberOfPlacesStillAvailable(): number {
    if (this.event.draft) return this.event.options.maximumAttendeeCapacity;
    return (
      this.event.options.maximumAttendeeCapacity -
      this.event.participantStats.participant
    );
  }

  get physicalAddress(): Address | null {
    if (!this.event.physicalAddress) return null;

    return new Address(this.event.physicalAddress);
  }

  async anonymousParticipationConfirmed(): Promise<boolean> {
    return isParticipatingInThisEvent(this.uuid);
  }

  async cancelAnonymousParticipation(): Promise<void> {
    const token = (await getLeaveTokenForParticipation(this.uuid)) as string;
    await this.leaveEvent(this.event, this.config.anonymous.actorId, token);
    await removeAnonymousParticipation(this.uuid);
    this.anonymousParticipation = null;
  }

  get ableToReport(): boolean {
    return (
      this.config &&
      (this.currentActor.id != null || this.config.anonymous.reports.allowed)
    );
  }

  get organizer(): IActor | null {
    if (this.event.attributedTo && this.event.attributedTo.id) {
      return this.event.attributedTo;
    }
    if (this.event.organizerActor) {
      return this.event.organizerActor;
    }
    return null;
  }

  get organizerDomain(): string | null {
    if (this.organizer) {
      return this.organizer.domain;
    }
    return null;
  }

  get shouldShowParticipationButton(): boolean {
    // So that people can cancel their participation
    if (
      this.actorIsParticipant ||
      (this.config.anonymous.participation.allowed &&
        this.anonymousParticipation)
    )
      return true;

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
}
</script>
<style lang="scss" scoped>
.section {
  padding: 1rem 2rem 4rem;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}

.header-picture,
.header-picture-default {
  height: 400px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}

.header-picture-default {
  background-image: url("/img/mobilizon_default_card.png");
}

div.sidebar {
  display: flex;
  flex-wrap: wrap;
  flex-direction: column;

  position: relative;

  &::before {
    content: "";
    background: #b3b3b2;
    position: absolute;
    bottom: 30px;
    top: 30px;
    left: 0;
    height: calc(100% - 60px);
    width: 1px;
  }

  div.organizer {
    display: inline-flex;
    padding-top: 10px;

    a {
      color: #4a4a4a;

      span {
        line-height: 2.7rem;
        padding-right: 6px;
      }
    }
  }
}

.intro.section {
  background: white;

  p.tags {
    a {
      text-decoration: none;
    }

    span {
      &.tag {
        margin: 0 2px;
      }
    }
  }
}

.event-description-wrapper {
  display: flex;
  flex-wrap: wrap;
  flex-direction: column;
  padding: 0;

  @media all and (min-width: 672px) {
    flex-direction: row-reverse;
  }

  & > aside,
  & > div {
    @media all and (min-width: 672px) {
      margin: 2rem auto;
    }
  }

  aside.event-metadata {
    min-width: 20rem;
    flex: 1;
    @media all and (min-width: 672px) {
      padding-left: 1rem;
    }

    .sticky {
      position: sticky;
      background: white;
      top: 50px;
      padding: 2rem;
    }

    div.address-wrapper {
      display: flex;
      flex: 1;
      flex-wrap: wrap;

      div.address {
        flex: 1;

        .map-show-button {
          cursor: pointer;
        }

        address {
          font-style: normal;
          flex-wrap: wrap;
          display: flex;
          justify-content: flex-start;

          span.addressDescription {
            text-overflow: ellipsis;
            white-space: nowrap;
            flex: 1 0 auto;
            min-width: 100%;
            max-width: 4rem;
            overflow: hidden;
          }

          :not(.addressDescription) {
            color: rgba(46, 62, 72, 0.6);
            flex: 1;
            min-width: 100%;
          }
        }
      }
    }

    span.online-address {
      display: flex;
    }
  }

  div.event-description-comments {
    min-width: 20rem;
    padding: 1rem;
    flex: 2;
    background: white;
  }

  .description-content {
    ::v-deep h1 {
      font-size: 2rem;
    }

    ::v-deep h2 {
      font-size: 1.5rem;
    }

    ::v-deep h3 {
      font-size: 1.25rem;
    }

    ::v-deep ul {
      list-style-type: disc;
    }

    ::v-deep li {
      margin: 10px auto 10px 2rem;
    }

    ::v-deep blockquote {
      border-left: 0.2em solid #333;
      display: block;
      padding-left: 1em;
    }

    ::v-deep p {
      margin: 10px auto;

      a {
        display: inline-block;
        padding: 0.3rem;
        background: $secondary;
        color: #111;

        &:empty {
          display: none;
        }
      }
    }
  }
}

.comments {
  padding-top: 3rem;

  a h3#comments {
    margin-bottom: 10px;
  }
}

.more-events {
  background: white;
}

.dropdown .dropdown-trigger span {
  cursor: pointer;
}

a.dropdown-item,
.dropdown .dropdown-menu .has-link a,
button.dropdown-item {
  white-space: nowrap;
  width: 100%;
  padding-right: 1rem;
  text-align: right;
}

a.participations-link {
  text-decoration: none;
}

.event-status .tag {
  font-size: 1rem;
}

.map-modal {
  .modal-card-head {
    justify-content: flex-end;
    button.delete {
      margin-right: 1rem;
    }
  }

  section.map {
    height: calc(100% - 8rem);
    width: calc(100% - 20px);
  }

  section.map-footer {
    p.address {
      margin: 1rem auto;
    }
    div.buttons {
      justify-content: center;
    }
  }
}

.no-border {
  border: 0;
  cursor: auto;
}
</style>
