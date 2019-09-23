<template>
  <div>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div v-if="event">
      <div class="header-picture container">
        <figure class="image is-3by1" v-if="event.picture">
          <img :src="event.picture.url">
        </figure>
        <figure class="image is-3by1" v-else>
          <img src="https://picsum.photos/600/200/">
        </figure>
      </div>
        <section class="container">
          <div class="title-and-participate-button">
            <div class="title-wrapper">
              <div class="date-component">
                <date-calendar-icon :date="event.beginsOn"></date-calendar-icon>
              </div>
              <h1 class="title">{{ event.title }}</h1>
            </div>
            <span v-if="event.participantStats.approved > 0 && !actorIsParticipant()">
                {{ $tc('One person is going', event.participantStats.approved, {approved: event.participantStats.approved}) }}
            </span>
            <span v-else>
              {{ $tc('You and one other person are going to this event', event.participantStats.approved - 1, {approved: event.participantStats.approved - 1}) }}
            </span>
            <div v-if="!actorIsOrganizer()" class="participate-button has-text-centered">
              <a v-if="!actorIsParticipant()" @click="isJoinModalActive = true" class="button is-large is-primary is-rounded">
                <b-icon icon="circle-outline"></b-icon>
                {{ $t('Join') }}
              </a>
              <a v-if="actorIsParticipant()" @click="confirmLeave()" class="button is-large is-primary is-rounded">
                <b-icon icon="check-circle"></b-icon>
                {{ $t('Leave') }}
              </a>
            </div>
          </div>
          <div class="metadata columns">
            <div class="column is-three-quarters-desktop">
              <p class="tags" v-if="event.category || event.tags.length > 0">
<!--                <span class="tag" v-if="event.category">{{ event.category }}</span>-->
                <span class="tag" v-if="event.tags" v-for="tag in event.tags">{{ tag.title }}</span>
                <span class="visibility">
                  <span v-if="event.visibility === EventVisibility.PUBLIC">{{ $t('Public event') }}</span>
                  <span v-if="event.visibility === EventVisibility.UNLISTED">{{ $t('Private event') }}</span>
                </span>
              </p>
              <div class="date-and-add-to-calendar">
                <div class="date-and-privacy" v-if="event.beginsOn">
                  <b-icon icon="calendar-clock" />
                  <event-full-date :beginsOn="event.beginsOn" :endsOn="event.endsOn" />
                </div>
                <a class="add-to-calendar" @click="downloadIcsEvent()">
                  <b-icon icon="calendar-plus" />
                  {{ $t('Add to my calendar') }}
                </a>
              </div>
              <p class="slug">
                {{ event.slug }}
              </p>
            </div>
            <div class="column sidebar">
              <div class="field has-addons">
                <p class="control" v-if="actorIsOrganizer()">
                  <router-link
                          class="button"
                          :to="{ name: 'EditEvent', params: {eventId: event.uuid}}"
                  >
                    {{ $t('Edit') }}
                  </router-link>
                </p>
                <p class="control" v-if="actorIsOrganizer()">
                  <a class="button is-danger" @click="openDeleteEventModalWrapper">
                    {{ $t('Delete') }}
                  </a>
                </p>
                <p class="control">
                  <a class="button is-danger" @click="isReportModalActive = true">
                    {{ $t('Report') }}
                  </a>
                </p>
              </div>
              <div class="address-wrapper">
                <b-icon icon="map" />
                <span v-if="!event.physicalAddress">{{ $t('No address defined') }}</span>
                <div class="address" v-if="event.physicalAddress">
                  <address>
                    <span class="addressDescription" :title="event.physicalAddress.description">{{ event.physicalAddress.description }}</span>
                    <span>{{ event.physicalAddress.floor }} {{ event.physicalAddress.street }}</span>
                    <span>{{ event.physicalAddress.postalCode }} {{ event.physicalAddress.locality }}</span>
  <!--                  <span>{{ event.physicalAddress.region }} {{ event.physicalAddress.country }}</span>-->
                  </address>
                  <span class="map-show-button" @click="showMap = !showMap" v-if="event.physicalAddress && event.physicalAddress.geom">
                    {{ $t('Show map') }}
                  </span>
                </div>
                <b-modal v-if="event.physicalAddress && event.physicalAddress.geom" :active.sync="showMap" scroll="keep">
                  <div class="map">
                    <map-leaflet
                            :coords="event.physicalAddress.geom"
                            :popup="event.physicalAddress.description"
                    />
                  </div>
                </b-modal>
              </div>
              <div class="organizer">
                <span>
                  <span v-if="event.organizerActor">
                    {{ $t('By {name}', {name: event.organizerActor.name ? event.organizerActor.name : event.organizerActor.preferredUsername}) }}
                  </span>
                  <figure v-if="event.organizerActor.avatar" class="image is-48x48">
                    <img
                            class="is-rounded"
                            :src="event.organizerActor.avatar.url"
                            :alt="event.organizerActor.avatar.alt" />
                  </figure>
                </span>
              </div>
            </div>
          </div>
        </section>
        <div class="description">
          <div class="description-container container">
            <h3 class="title">
              {{ $t('About this event') }}
            </h3>
            <p v-if="!event.description">
              {{ $t("The event organizer didn't add any description.") }}
            </p>
            <div class="columns" v-else>
              <div class="column is-half" v-html="event.description">
              </div>
            </div>
          </div>
        </div>
      <section class="container">
        <h3 class="title">{{ $t('Participants') }}</h3>
        <router-link v-if="currentActor.id === event.organizerActor.id" :to="{ name: EventRouteName.PARTICIPATIONS, params: { eventId: event.uuid } }">
          {{ $t('Manage participants') }}
        </router-link>
        <span v-if="event.participants.length === 0">{{ $t('No participants yet.') }}</span>
        <div class="columns">
          <div
            class="column"
            v-for="participant in event.participants"
            :key="participant.id"
          >
              <figure class="image is-48x48">
                <img v-if="!participant.actor.avatar.url" src="https://picsum.photos/48/48/" class="is-rounded">
                <img v-else :src="participant.actor.avatar.url" class="is-rounded">
              </figure>
              <span>{{ participant.actor.preferredUsername }}</span>
          </div>
        </div>
      </section>
      <section class="share">
        <div class="container">
          <div class="columns">
            <div class="column is-half has-text-centered">
              <h3 class="title">{{ $t('Share this event') }}</h3>
              <div>
                <b-icon icon="mastodon" size="is-large" type="is-primary" />
                <a :href="facebookShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="facebook" size="is-large" type="is-primary" /></a>
                <a :href="twitterShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="twitter" size="is-large" type="is-primary" /></a>
                <a :href="emailShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="email" size="is-large" type="is-primary" /></a>
                <!--     TODO: mailto: links are not used anymore, we should provide a popup to redact a message instead    -->
                <a :href="linkedInShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="linkedin" size="is-large" type="is-primary" /></a>
              </div>
            </div>
            <hr />
            <div class="column is-half has-text-right add-to-calendar">
              <h3 @click="downloadIcsEvent()">
                {{ $t('Add to my calendar') }}
              </h3>
            </div>
          </div>
        </div>
      </section>
      <section class="more-events container" v-if="event.relatedEvents.length > 0">
        <h3 class="title has-text-centered">{{ $t('These events may interest you') }}</h3>
        <div class="columns">
          <div class="column is-one-third-desktop" v-for="relatedEvent in event.relatedEvents" :key="relatedEvent.uuid">
            <EventCard :event="relatedEvent" />
          </div>
        </div>
      </section>
      <b-modal :active.sync="isReportModalActive" has-modal-card ref="reportModal">
        <report-modal :on-confirm="reportEvent" :title="$t('Report this event')" :outside-domain="event.organizerActor.domain" @close="$refs.reportModal.close()" />
      </b-modal>
      <b-modal :active.sync="isJoinModalActive" has-modal-card ref="participationModal">
        <participation-modal :on-confirm="joinEvent" :event="event" :defaultIdentity="currentActor" @close="$refs.participationModal.close()" />
      </b-modal>
      </div>
    </div>
</template>

<script lang="ts">
import { DELETE_EVENT, FETCH_EVENT, JOIN_EVENT, LEAVE_EVENT } from '@/graphql/event';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { EventVisibility, IEvent, IParticipant, ParticipantRole } from '@/types/event.model';
import { IPerson } from '@/types/actor';
import { RouteName } from '@/router';
import { GRAPHQL_API_ENDPOINT } from '@/api/_entrypoint';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import BIcon from 'buefy/src/components/icon/Icon.vue';
import EventCard from '@/components/Event/EventCard.vue';
import EventFullDate from '@/components/Event/EventFullDate.vue';
import ActorLink from '@/components/Account/ActorLink.vue';
import ReportModal from '@/components/Report/ReportModal.vue';
import ParticipationModal from '@/components/Event/ParticipationModal.vue';
import { IReport } from '@/types/report.model';
import { CREATE_REPORT } from '@/graphql/report';
import EventMixin from '@/mixins/event';
import { EventRouteName } from '@/router/event';

@Component({
  components: {
    ActorLink,
    EventFullDate,
    EventCard,
    BIcon,
    DateCalendarIcon,
    ReportModal,
    ParticipationModal,
    // tslint:disable:space-in-parens
    'map-leaflet': () => import(/* webpackChunkName: "map" */ '@/components/Map.vue'),
    // tslint:enable
  },
  apollo: {
    event: {
      query: FETCH_EVENT,
      variables() {
        return {
          uuid: this.uuid,
          roles: [ParticipantRole.CREATOR, ParticipantRole.MODERATOR, ParticipantRole.MODERATOR, ParticipantRole.PARTICIPANT].join(),
        };
      },
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class Event extends EventMixin {
  @Prop({ type: String, required: true }) uuid!: string;

  event!: IEvent;
  currentActor!: IPerson;
  validationSent: boolean = false;
  showMap: boolean = false;
  isReportModalActive: boolean = false;
  isJoinModalActive: boolean = false;

  EventVisibility = EventVisibility;
  EventRouteName = EventRouteName;

  /**
   * Delete the event, then redirect to home.
   */
  async openDeleteEventModalWrapper() {
    await this.openDeleteEventModal(this.event, this.currentActor);
  }

  async reportEvent(content: string, forward: boolean) {
    this.isReportModalActive = false;
    if (!this.event.organizerActor) return;
    const eventTitle = this.event.title;
    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          eventId: this.event.id,
          reporterActorId: this.currentActor.id,
          reportedActorId: this.event.organizerActor.id,
          content,
        },
      });
      this.$buefy.notification.open({
        message: this.$t('Event {eventTitle} reported', { eventTitle }) as string,
        type: 'is-success',
        position: 'is-bottom-right',
        duration: 5000,
      });
    } catch (error) {
      console.error(error);
    }
  }

  async joinEvent(identity: IPerson) {
    this.isJoinModalActive = false;
    try {
      await this.$apollo.mutate<{ joinEvent: IParticipant }>({
        mutation: JOIN_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: identity.id,
        },
        update: (store, { data }) => {
          if (data == null) return;
          const cachedData = store.readQuery<{ event: IEvent }>({ query: FETCH_EVENT, variables: { uuid: this.event.uuid } });
          if (cachedData == null) return;
          const { event } = cachedData;
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.');
            return;
          }

          event.participants = event.participants.concat([data.joinEvent]);

          store.writeQuery({ query: FETCH_EVENT, data: { event } });
        },
      });
    } catch (error) {
      console.error(error);
    }
  }

  confirmLeave() {
    this.$buefy.dialog.confirm({
      title: this.$t('Leaving event "{title}"', { title: this.event.title }) as string,
      message: this.$t('Are you sure you want to cancel your participation at event "{title}"?', { title: this.event.title }) as string,
      confirmText: this.$t('Leave event') as string,
      cancelText: this.$t('Cancel') as string,
      type: 'is-danger',
      hasIcon: true,
      onConfirm: () => this.leaveEvent(),
    });
  }

  async leaveEvent() {
    try {
      await this.$apollo.mutate<{ leaveEvent: IParticipant }>({
        mutation: LEAVE_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: this.currentActor.id,
        },
        update: (store, { data }) => {
          if (data == null) return;
          const cachedData = store.readQuery<{ event: IEvent }>({ query: FETCH_EVENT, variables: { uuid: this.event.uuid } });
          if (cachedData == null) return;
          const { event } = cachedData;
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.');
            return;
          }

          event.participants = event.participants
            .filter(p => p.actor.id !== data.leaveEvent.actor.id);
          event.participantStats.approved = event.participantStats.approved - 1;

          store.writeQuery({ query: FETCH_EVENT, data: { event } });
        },
      });
    } catch (error) {
      console.error(error);
    }
  }

  async downloadIcsEvent() {
    const data = await (await fetch(`${GRAPHQL_API_ENDPOINT}/events/${this.uuid}/export/ics`)).text();
    const blob = new Blob([data], { type: 'text/calendar' });
    const link = document.createElement('a');
    link.href = window.URL.createObjectURL(blob);
    link.download = `${this.event.title}.ics`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  actorIsParticipant() {
    if (this.actorIsOrganizer()) return true;

    return this.currentActor &&
      this.event.participants
          .some(participant => participant.actor.id === this.currentActor.id);
  }

  actorIsOrganizer() {
    return this.currentActor && this.event.organizerActor &&
      this.currentActor.id === this.event.organizerActor.id;
  }

  get twitterShareUrl(): string {
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(this.event.url)}&text=${this.event.title}`;
  }

  get facebookShareUrl(): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.event.url)}`;
  }

  get linkedInShareUrl(): string {
    return `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(this.event.url)}&title=${this.event.title}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.event.url}${encodeURIComponent('\n\n')}${this.event.description}&subject=${this.event.title}`;
  }

}
</script>
<style lang="scss" scoped>
  @import "../../variables";

  div.sidebar {
    display: flex;
    flex-wrap: wrap;
    flex-direction: column;

    position: relative;

    &::before {
      content: "";
      background: #B3B3B2;
      position: absolute;
      bottom: 30px;
      top: 30px;
      left: 0;
      height: calc(100% - 60px);
      width: 1px;
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
            color: rgba(46, 62, 72, .6);
            flex: 1;
            min-width: 100%;
          }
        }
      }

      div.map {
        height: 900px;
        width: 100%;
        padding: 25px 5px 0;
      }
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

  div.title-and-participate-button {
    display: flex;
    flex-wrap: wrap;
    /*flex-flow: row wrap;*/
    justify-content: space-between;
    /*align-self: center;*/
    align-items: stretch;
    /*align-content: space-around;*/
    padding: 15px 10px 0;

    div.title-wrapper {
      display: flex;
      flex: 1 1 auto;


      div.date-component {
        margin-right: 16px;
      }

      h1.title {
        font-weight: normal;
        word-break: break-word;
        font-size: 1.7em;
      }
    }

    .participate-button {
      flex: 0 1 auto;
      display: inline-flex;

      a.button {
        margin: 0 auto;
      }
    }
  }

  div.metadata {
    padding: 0 10px;

    div.date-and-add-to-calendar {
      display: flex;
      flex-wrap: wrap;

      span.icon {
        margin-right: 5px;
      }

      div.date-and-privacy {
        color: $primary;
        padding: 0.3rem;
        background: $secondary;
        font-weight: bold;
      }

      a.add-to-calendar {
        flex: 0 0 auto;
        margin-left: 10px;
        color: #484849;

        &:hover {
          text-decoration: underline;
        }
      }
    }
  }

  p.tags {
    span {
      &.tag {
        &::before {
          content: '#';
        }
        text-transform: uppercase;
      }

      &.visibility::before {
        content: "⋅"
      }


      margin: auto 5px;
    }
    margin-bottom: 1rem;
  }

  h3.title {
    font-size: 3rem;
    font-weight: 300;
  }

  .description {
    padding-top: 10px;
    min-height: 40rem;
    background-repeat: no-repeat;
    background-size: 800px;
    background-position: 95% 101%;
    background-image: url('../../assets/texting.svg');
    border-top: solid 1px #111;
    border-bottom: solid 1px #111;

    p {
      margin: 10px auto;

      a {
        display: inline-block;
        padding: 0.3rem;
        background: $secondary;
        color: #111;
      }
    }
  }

  .share {
    border-bottom: solid 1px #111;

    .columns {

      & > * {
        padding: 10rem 0;
      }

      .add-to-calendar {
        background-repeat: no-repeat;
        background-size: 400px;
        background-position: 10% 50%;
        background-image: url('../../assets/undraw_events.svg');
        position: relative;

        &::before {
          content:"";
          background: #B3B3B2;
          position: absolute;
          bottom: 25%;
          left: 0;
          height: 40%;
          width: 1px;
        }


        h3 {
          display: block;
          color: $primary;
          font-size: 3rem;
          text-decoration: underline;
          text-decoration-color: $secondary;
          cursor: pointer;
          max-width: 20rem;
          margin-right: 0;
          margin-left: auto;
        }
      }
    }
  }

  .more-events {
    margin: 50px auto;
  }
</style>
