<template>
  <article class="box mb-5 mt-4">
    <div class="identity-header">
      <figure class="image is-24x24" v-if="participation.actor.avatar">
        <img
          class="is-rounded"
          :src="participation.actor.avatar.url"
          alt=""
          height="24"
          width="24"
        />
      </figure>
      <b-icon v-else icon="account-circle" />
      {{ displayNameAndUsername(participation.actor) }}
    </div>
    <div class="list-card">
      <div class="content-and-actions">
        <div class="event-preview mr-0 ml-0">
          <div>
            <div class="date-component">
              <date-calendar-icon
                :date="participation.event.beginsOn"
                :small="true"
              />
            </div>
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: participation.event.uuid },
              }"
            >
              <lazy-image-wrapper
                :rounded="true"
                :picture="participation.event.picture"
                style="
                  height: 100%;
                  position: absolute;
                  top: 0;
                  left: 0;
                  width: 100%;
                "
              />
            </router-link>
          </div>
        </div>
        <div class="list-card-content">
          <div class="title-wrapper">
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: participation.event.uuid },
              }"
            >
              <h3 class="title">{{ participation.event.title }}</h3>
            </router-link>
          </div>
          <event-address
            v-if="participation.event.physicalAddress"
            class="event-subtitle"
            :physical-address="participation.event.physicalAddress"
          />
          <div
            class="event-subtitle"
            v-else-if="
              participation.event.options &&
              participation.event.options.isOnline
            "
          >
            <b-icon icon="video" />
            <span>{{ $t("Online") }}</span>
          </div>
          <div class="event-subtitle event-organizer">
            <figure
              class="image is-24x24"
              v-if="
                organizer(participation.event) &&
                organizer(participation.event).avatar
              "
            >
              <img
                class="is-rounded"
                :src="organizer(participation.event).avatar.url"
                alt=""
              />
            </figure>
            <b-icon v-else icon="account-circle" />
            <span class="organizer-name">
              {{ organizerDisplayName(participation.event) }}
            </span>
          </div>
          <div class="event-subtitle event-participants">
            <b-icon
              :class="{ 'has-text-danger': lastSeatsLeft }"
              icon="account-group"
            />
            <span
              class="participant-stats"
              v-if="participation.role !== ParticipantRole.NOT_APPROVED"
            >
              <!-- Less than 10 seats left -->
              <span class="has-text-danger" v-if="lastSeatsLeft">
                {{
                  $t("{number} seats left", {
                    number: seatsLeft,
                  })
                }}
              </span>
              <span
                v-else-if="
                  participation.event.options.maximumAttendeeCapacity !== 0
                "
              >
                {{
                  $tc(
                    "{available}/{capacity} available places",
                    participation.event.options.maximumAttendeeCapacity -
                      participation.event.participantStats.participant,
                    {
                      available:
                        participation.event.options.maximumAttendeeCapacity -
                        participation.event.participantStats.participant,
                      capacity:
                        participation.event.options.maximumAttendeeCapacity,
                    }
                  )
                }}
              </span>
              <span v-else>
                {{
                  $tc(
                    "{count} participants",
                    participation.event.participantStats.participant,
                    {
                      count: participation.event.participantStats.participant,
                    }
                  )
                }}
              </span>
              <b-button
                v-if="participation.event.participantStats.notApproved > 0"
                type="is-text"
                @click="
                  gotToWithCheck(participation, {
                    name: RouteName.PARTICIPATIONS,
                    query: { role: ParticipantRole.NOT_APPROVED },
                    params: { eventId: participation.event.uuid },
                  })
                "
              >
                {{
                  $tc(
                    "{count} requests waiting",
                    participation.event.participantStats.notApproved,
                    {
                      count: participation.event.participantStats.notApproved,
                    }
                  )
                }}
              </b-button>
            </span>
          </div>
        </div>
        <div class="actions">
          <b-dropdown aria-role="list" position="is-bottom-left">
            <b-button slot="trigger" role="button" icon-right="dots-horizontal">
              {{ $t("Actions") }}
            </b-button>

            <b-dropdown-item
              v-if="
                ![
                  ParticipantRole.PARTICIPANT,
                  ParticipantRole.NOT_APPROVED,
                ].includes(participation.role)
              "
              aria-role="listitem"
              @click="
                gotToWithCheck(participation, {
                  name: RouteName.EDIT_EVENT,
                  params: { eventId: participation.event.uuid },
                })
              "
            >
              <b-icon icon="pencil" />
              {{ $t("Edit") }}
            </b-dropdown-item>

            <b-dropdown-item
              v-if="participation.role === ParticipantRole.CREATOR"
              aria-role="listitem"
              @click="
                gotToWithCheck(participation, {
                  name: RouteName.DUPLICATE_EVENT,
                  params: { eventId: participation.event.uuid },
                })
              "
            >
              <b-icon icon="content-duplicate" />
              {{ $t("Duplicate") }}
            </b-dropdown-item>

            <b-dropdown-item
              v-if="
                ![
                  ParticipantRole.PARTICIPANT,
                  ParticipantRole.NOT_APPROVED,
                ].includes(participation.role)
              "
              aria-role="listitem"
              @click="openDeleteEventModalWrapper"
            >
              <b-icon icon="delete" />
              {{ $t("Delete") }}
            </b-dropdown-item>

            <b-dropdown-item
              v-if="
                ![
                  ParticipantRole.PARTICIPANT,
                  ParticipantRole.NOT_APPROVED,
                ].includes(participation.role)
              "
              aria-role="listitem"
              @click="
                gotToWithCheck(participation, {
                  name: RouteName.PARTICIPATIONS,
                  params: { eventId: participation.event.uuid },
                })
              "
            >
              <b-icon icon="account-multiple-plus" />
              {{ $t("Manage participations") }}
            </b-dropdown-item>

            <b-dropdown-item aria-role="listitem" has-link>
              <router-link
                :to="{
                  name: RouteName.EVENT,
                  params: { uuid: participation.event.uuid },
                }"
              >
                <b-icon icon="view-compact" />
                {{ $t("View event page") }}
              </router-link>
            </b-dropdown-item>
          </b-dropdown>
        </div>
      </div>
    </div>
  </article>
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { mixins } from "vue-class-component";
import { RawLocation, Route } from "vue-router";
import { EventVisibility, ParticipantRole } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import {
  IEventCardOptions,
  organizer,
  organizerDisplayName,
} from "../../types/event.model";
import { displayNameAndUsername, IActor, IPerson } from "../../types/actor";
import ActorMixin from "../../mixins/actor";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import EventMixin from "../../mixins/event";
import RouteName from "../../router/name";
import { changeIdentity } from "../../utils/auth";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import EventAddress from "@/components/Event/EventAddress.vue";
import { PropType } from "vue";

const defaultOptions: IEventCardOptions = {
  hideDate: true,
  loggedPerson: false,
  hideDetails: false,
  organizerActor: null,
  memberofGroup: false,
};

@Component({
  components: {
    DateCalendarIcon,
    PopoverActorCard,
    LazyImageWrapper,
    EventAddress,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EventParticipationCard extends mixins(
  ActorMixin,
  EventMixin
) {
  /**
   * The participation associated
   */
  @Prop({ required: true, type: Object as PropType<IParticipant> })
  participation!: IParticipant;

  /**
   * Options are merged with default options
   */
  @Prop({ required: false, default: () => defaultOptions })
  options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;

  EventVisibility = EventVisibility;

  displayNameAndUsername = displayNameAndUsername;

  organizerDisplayName = organizerDisplayName;

  organizer = organizer;

  RouteName = RouteName;

  get mergedOptions(): IEventCardOptions {
    return { ...defaultOptions, ...this.options };
  }

  /**
   * Delete the event
   */
  async openDeleteEventModalWrapper(): Promise<void> {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    await this.openDeleteEventModal(this.participation.event);
  }

  async gotToWithCheck(
    participation: IParticipant,
    route: RawLocation
  ): Promise<Route> {
    if (
      participation.actor.id !== this.currentActor.id &&
      participation.event.organizerActor
    ) {
      const organizerActor = participation.event.organizerActor as IPerson;
      await changeIdentity(this.$apollo.provider.defaultClient, organizerActor);
      this.$buefy.notification.open({
        message: this.$t(
          "Current identity has been changed to {identityName} in order to manage this event.",
          {
            identityName: organizerActor.preferredUsername,
          }
        ) as string,
        type: "is-info",
        position: "is-bottom-right",
        duration: 5000,
      });
    }
    return this.$router.push(route);
  }

  get organizerActor(): IActor | undefined {
    if (
      this.participation.event.attributedTo &&
      this.participation.event.attributedTo.id
    ) {
      return this.participation.event.attributedTo;
    }
    return this.participation.event.organizerActor;
  }

  get seatsLeft(): number | null {
    if (this.participation.event.options.maximumAttendeeCapacity > 0) {
      return (
        this.participation.event.options.maximumAttendeeCapacity -
        this.participation.event.participantStats.participant
      );
    }
    return null;
  }

  get lastSeatsLeft(): boolean {
    if (this.seatsLeft) {
      return this.seatsLeft < 10;
    }
    return false;
  }
}
</script>

<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
@use "@/styles/_event-card";
@import "~bulma/sass/utilities/mixins.sass";

article.box {
  div.tag-container {
    position: absolute;
    top: 10px;
    right: 0;
    @include margin-left(-5px);
    z-index: 10;
    max-width: 40%;

    span.tag {
      margin: 5px auto;
      box-shadow: 0 0 5px 0 rgba(0, 0, 0, 1);
      /*word-break: break-all;*/
      text-overflow: ellipsis;
      overflow: hidden;
      display: block;
      /*text-align: right;*/
      font-size: 1em;
      /*padding: 0 1px;*/
      line-height: 1.75em;
    }
  }

  .list-card {
    display: flex;
    padding: 0 6px 0 0;
    position: relative;
    flex-direction: column;

    .content-and-actions {
      display: grid;
      grid-gap: 5px 10px;
      grid-template-areas: "preview" "body" "actions";

      @include tablet {
        grid-template-columns: 1fr 3fr;
        grid-template-areas: "preview body" "actions actions";
      }

      @include desktop {
        grid-template-columns: 1fr 3fr 1fr;
        grid-template-areas: "preview body actions";
      }

      .event-preview {
        grid-area: preview;

        & > div {
          height: 128px;
          width: 100%;
          position: relative;

          div.date-component {
            display: flex;
            position: absolute;
            bottom: 5px;
            left: 5px;
            z-index: 1;
          }

          img {
            width: 100%;
            object-position: center;
            object-fit: cover;
            height: 100%;
          }
        }
      }

      .actions {
        padding: 7px;
        cursor: pointer;
        align-self: center;
        justify-self: center;
        grid-area: actions;
      }

      div.list-card-content {
        flex: 1;
        padding: 5px;
        grid-area: body;

        .participant-stats {
          display: flex;
          align-items: center;
          padding: 0 5px;
        }

        div.title-wrapper {
          display: flex;
          align-items: center;
          padding-top: 5px;

          a {
            text-decoration: none;
            padding-bottom: 5px;
          }

          .title {
            display: -webkit-box;
            -webkit-line-clamp: 3;
            -webkit-box-orient: vertical;
            overflow: hidden;
            font-size: 18px;
            line-height: 24px;
            margin: auto 0;
            font-weight: bold;
            color: $title-color;
          }
        }
      }
    }
  }

  .identity-header {
    background: $yellow-2;
    display: flex;
    padding: 5px;

    figure,
    span.icon {
      @include padding-right(3px);
    }
  }

  & > .columns {
    padding: 1.25rem;
  }
  padding: 0;
}
</style>
