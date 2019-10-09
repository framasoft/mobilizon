<docs>
A simple card for a participation (we should rename it)

```vue
<template>
  <div>
    <EventListCard
      :participation="participation"
      />
  </div>
</template>
<script>
export default {
  data() {
    return {
      participation: {
        event: { 
          title: 'Vue Styleguidist first meetup: learn the basics!',
          id: 5,
          uuid: 'some uuid',
          beginsOn: new Date(),
          organizerActor: {
            preferredUsername: 'tcit',
            name: 'Some Random Dude',
            domain: null,
            id: 4,
            displayName() { return 'Some random dude' }
          },
          options: {
            maximumAttendeeCapacity: 4
          },
          participantStats: {
            approved: 1,
            unapproved: 2
          }
        },
        actor: {
          preferredUsername: 'tcit',
            name: 'Some Random Dude',
            domain: null,
            id: 4,
            displayName() { return 'Some random dude' }
        },
        role: 'CREATOR',
      }
    }
  }
}
</script>
```
</docs>

<template>
  <article class="box">
    <div class="columns">
      <div class="content column">
        <div class="title-wrapper">
          <div class="date-component" v-if="!mergedOptions.hideDate">
            <date-calendar-icon :date="participation.event.beginsOn" />
          </div>
          <h2 class="title">{{ participation.event.title }}</h2>
        </div>
        <div>
          <span v-if="participation.event.physicalAddress && participation.event.physicalAddress.locality">{{ participation.event.physicalAddress.locality }} - </span>
          <span v-if="participation.actor.id === participation.event.organizerActor.id">{{ $t("You're organizing this event") }}</span>
          <span v-else>
            <span v-if="participation.event.beginsOn < new Date()">{{ $t('Organized by {name}', { name: participation.event.organizerActor.displayName() } ) }}</span>
            |
            <span>{{ $t('Going as {name}', { name: participation.actor.displayName() }) }}</span>
          </span>
        </div>
        <div class="columns">
          <span class="column is-narrow">
            <b-icon icon="earth" v-if=" participation.event.visibility === EventVisibility.PUBLIC" />
            <b-icon icon="lock_opened" v-if=" participation.event.visibility === EventVisibility.RESTRICTED" />
            <b-icon icon="lock" v-if=" participation.event.visibility === EventVisibility.PRIVATE" />
          </span>
          <span class="column">
            <span v-if="!participation.event.options.maximumAttendeeCapacity">
              {{ $tc('{count} participants', participation.event.participantStats.approved, { count: participation.event.participantStats.approved })}}
            </span>
            <b-progress
                    v-if="participation.event.options.maximumAttendeeCapacity > 0"
                    type="is-primary"
                    size="is-medium"
                    :value="participation.event.participantStats.approved * 100 / participation.event.options.maximumAttendeeCapacity" show-value>
              {{ $t('{approved} / {total} seats', {approved: participation.event.participantStats.approved, total: participation.event.options.maximumAttendeeCapacity }) }}
            </b-progress>
            <span
              v-if="participation.event.participantStats.unapproved > 0">
              {{ $tc('{count} requests waiting', participation.event.participantStats.unapproved, { count: participation.event.participantStats.unapproved })}}
            </span>
          </span>
        </div>
      </div>
      <div class="actions column is-narrow">
        <ul>
          <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
            <router-link :to="{ name: RouteName.EDIT_EVENT, params: { eventId: participation.event.uuid }  }">
              <b-icon icon="pencil" /> {{ $t('Edit') }}
            </router-link>
          </li>
          <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
            <a @click="openDeleteEventModalWrapper"><b-icon icon="delete" /> {{ $t('Delete') }}</a>
          </li>
          <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
            <router-link :to="{ name: RouteName.PARTICIPATIONS, params: { eventId: participation.event.uuid } }">
              <b-icon icon="account-multiple-plus" /> {{ $t('Manage participations') }}
            </router-link>
          </li>
          <li>
            <router-link :to="{ name: RouteName.EVENT, params: { uuid: participation.event.uuid } }"><b-icon icon="view-compact" /> {{ $t('View event page') }}</router-link>
          </li>
        </ul>
      </div>
    </div>
    </article>
</template>

<script lang="ts">
import { IParticipant, ParticipantRole, EventVisibility } from '@/types/event.model';
import { Component, Prop } from 'vue-property-decorator';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import { IActor, IPerson, Person } from '@/types/actor';
import { mixins } from 'vue-class-component';
import ActorMixin from '@/mixins/actor';
import { CURRENT_ACTOR_CLIENT, LOGGED_USER_PARTICIPATIONS } from '@/graphql/actor';
import EventMixin from '@/mixins/event';
import { RouteName } from '@/router';
import { ICurrentUser } from '@/types/current-user.model';
import { IEventCardOptions } from './EventCard.vue';

const defaultOptions: IEventCardOptions = {
  hideDate: true,
  loggedPerson: false,
  hideDetails: false,
  organizerActor: null,
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
export default class EventListCard extends mixins(ActorMixin, EventMixin) {
  /**
   * The participation associated
   */
  @Prop({ required: true }) participation!: IParticipant;
  /**
   * Options are merged with default options
   */
  @Prop({ required: false, default: () => defaultOptions }) options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;
  EventVisibility = EventVisibility;
  RouteName = RouteName;

  get mergedOptions(): IEventCardOptions {
    return { ...defaultOptions, ...this.options };
  }

  /**
   * Delete the event
   */
  async openDeleteEventModalWrapper() {
    await this.openDeleteEventModal(this.participation.event, this.currentActor);
  }

}
</script>

<style lang="scss">
  @import "../../variables";

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
    div.content {
      padding: 5px;

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

      progress + .progress-value {
        color: $primary !important;
      }
    }

    .actions {
      ul li {
        margin: 0 auto;

        * {
          font-size: 0.8rem;
          color: $primary;
        }
      }
    }
  }

</style>
