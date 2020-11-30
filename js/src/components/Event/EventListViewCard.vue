<template>
  <article class="box">
    <div class="columns">
      <div class="content column">
        <div class="title-wrapper">
          <div class="date-component">
            <date-calendar-icon :date="event.beginsOn" />
          </div>
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
          >
            <h2 class="title">{{ event.title }}</h2>
          </router-link>
        </div>
        <div class="participation-actor has-text-grey">
          <span v-if="event.physicalAddress && event.physicalAddress.locality">
            {{ event.physicalAddress.locality }}
          </span>
          <span v-if="event.attributedTo && options.memberofGroup">
            {{
              $t("Created by {name}", {
                name: usernameWithDomain(event.organizerActor),
              })
            }}
          </span>
          <span v-else-if="options.memberofGroup">
            {{
              $t("Organized by {name}", {
                name: usernameWithDomain(event.organizerActor),
              })
            }}
          </span>
        </div>
        <div class="columns">
          <span class="column is-narrow">
            <b-icon
              icon="earth"
              v-if="event.visibility === EventVisibility.PUBLIC"
            />
            <b-icon
              icon="link"
              v-if="event.visibility === EventVisibility.UNLISTED"
            />
            <b-icon
              icon="lock"
              v-if="event.visibility === EventVisibility.PRIVATE"
            />
          </span>
          <span class="column is-narrow participant-stats">
            <span v-if="event.options.maximumAttendeeCapacity !== 0">
              {{
                $t("{approved} / {total} seats", {
                  approved: event.participantStats.participant,
                  total: event.options.maximumAttendeeCapacity,
                })
              }}
            </span>
            <span v-else>
              {{
                $tc(
                  "{count} participants",
                  event.participantStats.participant,
                  {
                    count: event.participantStats.participant,
                  }
                )
              }}
            </span>
          </span>
        </div>
      </div>
    </div>
  </article>
</template>

<script lang="ts">
import { IEventCardOptions, IEvent } from "@/types/event.model";
import { Component, Prop } from "vue-property-decorator";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { IPerson, usernameWithDomain } from "@/types/actor";
import { mixins } from "vue-class-component";
import ActorMixin from "@/mixins/actor";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import EventMixin from "@/mixins/event";
import { EventVisibility, ParticipantRole } from "@/types/enums";
import RouteName from "../../router/name";

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
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EventListViewCard extends mixins(ActorMixin, EventMixin) {
  /**
   * The participation associated
   */
  @Prop({ required: true }) event!: IEvent;

  /**
   * Options are merged with default options
   */
  @Prop({ required: false, default: () => defaultOptions })
  options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;

  EventVisibility = EventVisibility;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
}
</script>

<style lang="scss" scoped>
article.box {
  div.content {
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

      .title {
        display: -webkit-box;
        -webkit-line-clamp: 1;
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
</style>
