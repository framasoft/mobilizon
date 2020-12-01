<template>
  <article class="box">
    <div class="identity-header">
      <figure class="image is-24x24" v-if="participation.actor.avatar">
        <img class="is-rounded" :src="participation.actor.avatar.url" alt="" />
      </figure>
      {{ displayNameAndUsername(participation.actor) }}
    </div>
    <div class="list-card">
      <div class="content">
        <div class="title-wrapper">
          <div class="date-component">
            <date-calendar-icon :date="participation.event.beginsOn" />
          </div>
          <router-link
            :to="{
              name: RouteName.EVENT,
              params: { uuid: participation.event.uuid },
            }"
          >
            <h3 class="title">{{ participation.event.title }}</h3>
          </router-link>
        </div>
        <div class="participation-actor has-text-grey">
          <span>
            <b-icon
              icon="earth"
              v-if="participation.event.visibility === EventVisibility.PUBLIC"
            />
            <b-icon
              icon="link"
              v-else-if="
                participation.event.visibility === EventVisibility.UNLISTED
              "
            />
            <b-icon
              icon="lock"
              v-else-if="
                participation.event.visibility === EventVisibility.PRIVATE
              "
            />
          </span>
          <span
            v-if="
              participation.event.physicalAddress &&
              participation.event.physicalAddress.locality
            "
            >{{ participation.event.physicalAddress.locality }} -</span
          >
          <span>
            <i18n tag="span" path="Organized by {name}">
              <popover-actor-card
                slot="name"
                :actor="organizerActor"
                :inline="true"
              >
                {{ organizerActor.displayName() }}
              </popover-actor-card>
            </i18n>
          </span>
        </div>
        <div>
          <span
            class="participant-stats"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
          >
            <span
              v-if="participation.event.options.maximumAttendeeCapacity !== 0"
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
            <span v-if="participation.event.participantStats.notApproved > 0">
              <b-button
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
                    { count: participation.event.participantStats.notApproved }
                  )
                }}
              </b-button>
            </span>
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
  </article>
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { mixins } from "vue-class-component";
import { RawLocation, Route } from "vue-router";
import { EventVisibility, ParticipantRole } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import { IEventCardOptions } from "../../types/event.model";
import { displayNameAndUsername, IActor, IPerson } from "../../types/actor";
import ActorMixin from "../../mixins/actor";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import EventMixin from "../../mixins/event";
import RouteName from "../../router/name";
import { changeIdentity } from "../../utils/auth";
import PopoverActorCard from "../Account/PopoverActorCard.vue";

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
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EventListCard extends mixins(ActorMixin, EventMixin) {
  /**
   * The participation associated
   */
  @Prop({ required: true }) participation!: IParticipant;

  /**
   * Options are merged with default options
   */
  @Prop({ required: false, default: () => defaultOptions })
  options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;

  EventVisibility = EventVisibility;

  displayNameAndUsername = displayNameAndUsername;

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
      const organizer = participation.event.organizerActor as IPerson;
      await changeIdentity(this.$apollo.provider.defaultClient, organizer);
      this.$buefy.notification.open({
        message: this.$t(
          "Current identity has been changed to {identityName} in order to manage this event.",
          {
            identityName: organizer.preferredUsername,
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
}
</script>

<style lang="scss" scoped>
article.box {
  div.tag-container {
    position: absolute;
    top: 10px;
    right: 0;
    margin-right: -5px;
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
    align-items: center;

    .actions {
      padding-right: 7.5px;
      cursor: pointer;
    }

    div.content {
      flex: 1;
      padding: 5px;

      .participation-actor span,
      .participant-stats span {
        padding: 0 5px;

        button {
          height: auto;
          padding-top: 0;
        }
      }

      div.title-wrapper {
        display: flex;
        align-items: center;

        div.date-component {
          flex: 0;
          margin-right: 16px;
        }

        a {
          text-decoration: none;
        }

        .title {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
          font-weight: 400;
          line-height: 1em;
          font-size: 1.6em;
          padding-bottom: 5px;
          margin: auto 0;
        }
      }
    }
  }

  .identity-header {
    background: $yellow-2;
    display: flex;
    padding: 5px;

    figure {
      padding-right: 3px;
    }
  }

  & > .columns {
    padding: 1.25rem;
  }
  padding: 0;
}
</style>
