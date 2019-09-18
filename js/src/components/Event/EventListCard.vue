<template>
  <article class="box columns">
    <div class="content column">
      <div class="title-wrapper">
        <div class="date-component" v-if="!mergedOptions.hideDate">
          <date-calendar-icon :date="participation.event.beginsOn" />
        </div>
        <h2 class="title" ref="title">{{ participation.event.title }}</h2>
      </div>
      <div>
        <span v-if="participation.event.physicalAddress && participation.event.physicalAddress.locality">{{ participation.event.physicalAddress.locality }} - </span>
        <span v-if="participation.actor.id === participation.event.organizerActor.id">{{ $t("You're organizing this event") }}</span>
        <span v-else>
          <span>{{ $t('Organized by {name}', { name: participation.event.organizerActor.displayName() } ) }}</span> |
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
          <router-link :to="{ name: EventRouteName.EDIT_EVENT, params: { eventId: participation.event.uuid }  }">
            <b-icon icon="pencil" /> {{ $t('Edit') }}
          </router-link>
        </li>
        <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
          <a @click="openDeleteEventModalWrapper"><b-icon icon="delete" /> {{ $t('Delete') }}</a>
        </li>
        <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
          <a @click="">
            <b-icon icon="account-multiple-plus" /> {{ $t('Manage participations') }}
          </a>
        </li>
        <li>
          <router-link :to="{ name: EventRouteName.EVENT, params: { uuid: participation.event.uuid } }"><b-icon icon="view-compact" /> {{ $t('View event page') }}</router-link>
        </li>
      </ul>
    </div>
    </article>
</template>

<script lang="ts">
import { IParticipant, ParticipantRole, EventVisibility } from '@/types/event.model';
import { Component, Prop } from 'vue-property-decorator';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import { IActor, IPerson, Person } from '@/types/actor';
import { EventRouteName } from '@/router/event';
import { mixins } from 'vue-class-component';
import ActorMixin from '@/mixins/actor';
import { CURRENT_ACTOR_CLIENT, LOGGED_USER_PARTICIPATIONS } from '@/graphql/actor';
import EventMixin from '@/mixins/event';
import { RouteName } from '@/router';
import { ICurrentUser } from '@/types/current-user.model';
import { IEventCardOptions } from './EventCard.vue';
const lineClamp = require('line-clamp');

@Component({
  components: {
    DateCalendarIcon,
  },
  mounted() {
    lineClamp(this.$refs.title, 3);
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EventListCard extends mixins(ActorMixin, EventMixin) {
  @Prop({ required: true }) participation!: IParticipant;
  @Prop({ required: false }) options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;
  EventRouteName = EventRouteName;
  EventVisibility = EventVisibility;

  defaultOptions: IEventCardOptions = {
    hideDate: true,
    loggedPerson: false,
    hideDetails: false,
    organizerActor: null,
  };

  get mergedOptions(): IEventCardOptions {
    return { ...this.defaultOptions, ...this.options };
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

        div.date-component {
          flex: 0;
          margin-right: 16px;
        }

        .title {
          font-weight: 400;
          line-height: 1em;
          font-size: 1.6em;
          padding-bottom: 5px;
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
