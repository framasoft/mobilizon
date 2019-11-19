<template>
  <div class="container">
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <transition appear name="fade" mode="out-in">
      <div v-if="event">
        <div class="header-picture" v-if="event.picture" :style="`background-image: url('${event.picture.url}')`" />
        <div class="header-picture-default" v-else />
          <section>
            <div class="title-and-participate-button">
              <div class="title-wrapper">
                <div class="date-component">
                  <date-calendar-icon :date="event.beginsOn"></date-calendar-icon>
                </div>
                <div class="title-and-informations">
                  <h1 class="title">{{ event.title }}</h1>
                  <span>
                    <router-link v-if="actorIsOrganizer && event.draft === false" :to="{ name: RouteName.PARTICIPATIONS, params: {eventId: event.uuid}}">
                      <small v-if="event.participantStats.going > 0 && !actorIsParticipant">
                        {{ $tc('One person is going', event.participantStats.going, {approved: event.participantStats.going}) }}
                      </small>
                      <small v-else-if="event.participantStats.going > 0 && actorIsParticipant">
                        {{ $tc('You and one other person are going to this event', event.participantStats.participant, { approved: event.participantStats.participant }) }}
                      </small>
                    </router-link>
                    <small v-if="event.participantStats.going > 0 && !actorIsParticipant && !actorIsOrganizer">
                      {{ $tc('One person is going', event.participantStats.going, {approved: event.participantStats.going}) }}
                    </small>
                    <small v-else-if="event.participantStats.going > 0 && actorIsParticipant && !actorIsOrganizer">
                      {{ $tc('You and one other person are going to this event', event.participantStats.participant, { approved: event.participantStats.participant }) }}
                    </small>
                    <small v-if="event.options.maximumAttendeeCapacity">
                        {{ $tc('All the places have already been taken', numberOfPlacesStillAvailable, { places: numberOfPlacesStillAvailable}) }}
                    </small>
                  </span>
                </div>
              </div>
              <div class="event-participation has-text-right" v-if="new Date(endDate) > new Date()">
                <participation-button
                        v-if="currentActor.id && !actorIsOrganizer && !event.draft && (eventCapacityOK || actorIsParticipant) && event.status !== EventStatus.CANCELLED"
                        :participation="participations[0]"
                        :current-actor="currentActor"
                        @joinEvent="joinEvent"
                        @joinModal="isJoinModalActive = true"
                        @confirmLeave="confirmLeave"
                />
              </div>
              <div v-else>
                <button class="button is-primary" type="button" slot="trigger" disabled>
                  <template>
                    <span>{{ $t('Event already passed')}}</span>
                  </template>
                  <b-icon icon="menu-down"></b-icon>
                </button>
              </div>
            </div>
            <div class="metadata columns">
              <div class="column is-three-quarters-desktop">
                <p class="tags">
                  <b-tag type="is-warning" size="is-medium" v-if="event.draft">{{ $t('Draft') }}</b-tag>
                  <span class="event-status" v-if="event.status !== EventStatus.CONFIRMED">
                    <b-tag type="is-warning" v-if="event.status === EventStatus.TENTATIVE">{{ $t('Event to be confirmed') }}</b-tag>
                    <b-tag type="is-danger" v-if="event.status === EventStatus.CANCELLED">{{ $t('Event cancelled') }}</b-tag>
                  </span>
                  <span class="visibility" v-if="!event.draft">
                    <b-tag type="is-info" v-if="event.visibility === EventVisibility.PUBLIC">{{ $t('Public event') }}</b-tag>
                    <b-tag type="is-info" v-if="event.visibility === EventVisibility.UNLISTED">{{ $t('Private event') }}</b-tag>
                  </span>
                  <router-link
                    v-if="event.tags && event.tags.length > 0"
                    v-for="tag in event.tags"
                    :key="tag.title"
                    :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
                  >
                    <b-tag type="is-success" >{{ tag.title }}</b-tag>
                  </router-link>
                </p>
                <div class="date-and-add-to-calendar">
                  <div class="date-and-privacy" v-if="event.beginsOn">
                    <b-icon icon="calendar-clock" />
                    <event-full-date :beginsOn="event.beginsOn" :show-start-time="event.options.showStartTime" :show-end-time="event.options.showEndTime" :endsOn="event.endsOn" />
                  </div>
                  <a class="add-to-calendar" @click="downloadIcsEvent()" v-if="!event.draft">
                    <b-icon icon="calendar-plus" />
                    {{ $t('Add to my calendar') }}
                  </a>
                </div>
                <p class="slug">
                  {{ event.slug }}
                </p>
              </div>
              <div class="column sidebar">
                <div class="field has-addons" v-if="currentActor.id">
                  <p class="control" v-if="actorIsOrganizer || event.draft">
                    <router-link
                            class="button"
                            :to="{ name: RouteName.EDIT_EVENT, params: {eventId: event.uuid}}"
                    >
                      {{ $t('Edit') }}
                    </router-link>
                  </p>
                  <p class="control" v-if="actorIsOrganizer || event.draft">
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
                  <span v-if="!physicalAddress">
                    <b-icon icon="map" />
                    {{ $t('No address defined') }}
                  </span>
                  <div class="address" v-if="physicalAddress">
                    <span>
                      <b-icon :icon="physicalAddress.poiInfos.poiIcon.icon" />
                      <address>
                        <span class="addressDescription" :title="physicalAddress.poiInfos.name">{{ physicalAddress.poiInfos.name }}</span>
                        <span>{{ physicalAddress.poiInfos.alternativeName }}</span>
                      </address>
                    </span>
                    <span class="map-show-button" @click="showMap = !showMap" v-if="physicalAddress && physicalAddress.geom">
                      {{ $t('Show map') }}
                    </span>
                  </div>
                  <b-modal v-if="physicalAddress && physicalAddress.geom" :active.sync="showMap" scroll="keep">
                    <div class="map">
                      <map-leaflet
                              :coords="physicalAddress.geom"
                              :marker="{ text: physicalAddress.fullName, icon: physicalAddress.poiInfos.poiIcon.icon }"
                      />
                    </div>
                  </b-modal>
                </div>
                <span class="online-address" v-if="event.onlineAddress && urlToHostname(event.onlineAddress)">
                  <b-icon icon="link"></b-icon>
                  <a
                          target="_blank"
                          rel="noopener noreferrer"
                          :href="event.onlineAddress"
                          :title="$t('View page on {hostname} (in a new window)', {hostname: urlToHostname(event.onlineAddress) })"
                  >{{ urlToHostname(event.onlineAddress) }}</a>
                </span>
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
                <div class="column is-half description-content" ref="eventDescriptionElement" v-html="event.description">
                </div>
              </div>
            </div>
          </div>
        <section class="share" v-if="!event.draft">
          <div class="container">
            <div class="columns is-centered is-multiline">
              <div class="column is-half-widescreen has-text-centered">
                <h3 class="title">{{ $t('Share this event') }}</h3>
                <small class="maximumNumberOfPlacesWarning" v-if="!eventCapacityOK">
                  {{ $t('All the places have already been taken') }}
                </small>
                <div>
<!--                  <b-icon icon="mastodon" size="is-large" type="is-primary" />-->

                  <a :href="twitterShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="twitter" size="is-large" type="is-primary" /></a>
                  <a :href="facebookShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="facebook" size="is-large" type="is-primary" /></a>
                  <a :href="linkedInShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="linkedin" size="is-large" type="is-primary" /></a>
                  <a :href="diasporaShareUrl" class="diaspora" target="_blank" rel="nofollow noopener">
                    <span data-v-5e15e80a="" class="icon has-text-primary is-large">
                      <img svg-inline src="../../assets/diaspora-icon.svg" alt="diaspora-logo" />
                    </span>
                  </a>
                  <a :href="emailShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="email" size="is-large" type="is-primary" /></a>
                  <!--     TODO: mailto: links are not used anymore, we should provide a popup to redact a message instead    -->
                </div>
              </div>
              <hr />
              <div class="column is-half-widescreen has-text-right add-to-calendar">
                <img src="../../assets/undraw_events.svg" class="is-hidden-mobile is-hidden-tablet-only" />
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
              <identity-picker v-model="identity">
                <template v-slot:footer>
                  <footer class="modal-card-foot">
                    <button
                            class="button"
                            ref="cancelButton"
                            @click="isJoinModalActive = false">
                      {{ $t('Cancel') }}
                    </button>
                    <button
                            class="button is-primary"
                            ref="confirmButton"
                            @click="joinEvent(identity)">
                      {{ $t('Confirm my particpation') }}
                    </button>
                  </footer>
                </template>
              </identity-picker>
        </b-modal>
        </div>
    </transition>
  </div>
</template>

<script lang="ts">
import { EVENT_PERSON_PARTICIPATION, FETCH_EVENT, JOIN_EVENT, LEAVE_EVENT } from '@/graphql/event';
import { Component, Prop } from 'vue-property-decorator';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { EventStatus, EventVisibility, IEvent, IParticipant, ParticipantRole } from '@/types/event.model';
import { IPerson, Person } from '@/types/actor';
import { GRAPHQL_API_ENDPOINT } from '@/api/_entrypoint';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import BIcon from 'buefy/src/components/icon/Icon.vue';
import EventCard from '@/components/Event/EventCard.vue';
import EventFullDate from '@/components/Event/EventFullDate.vue';
import ActorLink from '@/components/Account/ActorLink.vue';
import ReportModal from '@/components/Report/ReportModal.vue';
import { IReport } from '@/types/report.model';
import { CREATE_REPORT } from '@/graphql/report';
import EventMixin from '@/mixins/event';
import IdentityPicker from '@/views/Account/IdentityPicker.vue';
import ParticipationButton from '@/components/Event/ParticipationButton.vue';
import { GraphQLError } from 'graphql';
import { RouteName } from '@/router';
import { Address } from '@/types/address.model';

@Component({
  components: {
    ActorLink,
    EventFullDate,
    EventCard,
    BIcon,
    DateCalendarIcon,
    ReportModal,
    IdentityPicker,
    ParticipationButton,
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
      variables() {
        return {
          eventId: this.event.id,
          actorId: this.currentActor.id,
        };
      },
      update: (data) => {
        if (data && data.person) return data.person.participations;
        return [];
      },
      skip() {
        return !this.currentActor || !this.event || !this.event.id || !this.currentActor.id;
      },
    },
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // @ts-ignore
      title: this.eventTitle,
      // all titles will be injected into this template
      titleTemplate: '%s | Mobilizon',
      meta: [
        // @ts-ignore
        { name: 'description', content: this.eventDescription },
      ],
    };
  },
})
export default class Event extends EventMixin {
  @Prop({ type: String, required: true }) uuid!: string;

  event!: IEvent;
  currentActor!: IPerson;
  identity: IPerson = new Person();
  participations: IParticipant[] = [];
  showMap: boolean = false;
  isReportModalActive: boolean = false;
  isJoinModalActive: boolean = false;
  EventVisibility = EventVisibility;
  EventStatus = EventStatus;
  RouteName = RouteName;

  get eventTitle() {
    if (!this.event) return undefined;
    return this.event.title;
  }

  get eventDescription() {
    if (!this.event) return undefined;
    return this.event.description;
  }

  mounted() {
    this.identity = this.currentActor;

    this.$watch('eventDescription', function (eventDescription) {
      if (!eventDescription) return;
      const eventDescriptionElement = this.$refs['eventDescriptionElement'] as HTMLElement;

      eventDescriptionElement.addEventListener('click', ($event) => {
        // TODO: Find the right type for target
        let { target } : { target: any } = $event;
        while (target && target.tagName !== 'A') target = target.parentNode;
        // handle only links that occur inside the component and do not reference external resources
        if (target && target.matches('.hashtag') && target.href) {
          // some sanity checks taken from vue-router:
          // https://github.com/vuejs/vue-router/blob/dev/src/components/link.js#L106
          const { altKey, ctrlKey, metaKey, shiftKey, button, defaultPrevented } = $event;
          // don't handle with control keys
          if (metaKey || altKey || ctrlKey || shiftKey) return;
          // don't handle when preventDefault called
          if (defaultPrevented) return;
          // don't handle right clicks
          if (button !== undefined && button !== 0) return;
          // don't handle if `target="_blank"`
          if (target && target.getAttribute) {
            const linkTarget = target.getAttribute('target');
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
  }

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
      const { data } = await this.$apollo.mutate<{ joinEvent: IParticipant }>({
        mutation: JOIN_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: identity.id,
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
            console.error('Cannot update participation cache, because of null value.');
            return;
          }
          person.participations.push(data.joinEvent);
          store.writeQuery({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: identity.id },
            data: { person },
          });

          const cachedData = store.readQuery<{ event: IEvent }>({ query: FETCH_EVENT, variables: { uuid: this.event.uuid } });
          if (cachedData == null) return;
          const { event } = cachedData;
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.');
            return;
          }

          if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
            event.participantStats.notApproved = event.participantStats.notApproved + 1;
          } else {
            event.participantStats.going = event.participantStats.going + 1;
            event.participantStats.participant = event.participantStats.participant + 1;
          }

          store.writeQuery({ query: FETCH_EVENT, variables: { uuid: this.uuid }, data: { event } });
        },
      });
      if (data) {
        this.$buefy.notification.open({
          message: (data.joinEvent.role === ParticipantRole.NOT_APPROVED ? this.$t('Your participation has been requested') : this.$t('Your participation has been confirmed')) as string,
          type: 'is-success',
          position: 'is-bottom-right',
          duration: 5000,
        });
      }
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
      const { data } = await this.$apollo.mutate<{ leaveEvent: IParticipant }>({
        mutation: LEAVE_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: this.currentActor.id,
        },
        update: (store, { data }) => {
          if (data == null) return;

          const participationCachedData = store.readQuery<{ person: IPerson }>({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: this.currentActor.id },
          });
          if (participationCachedData == null) return;
          const { person } = participationCachedData;
          if (person === null) {
            console.error('Cannot update participation cache, because of null value.');
            return;
          }
          const participation = person.participations[0];
          person.participations = [];
          store.writeQuery({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: this.currentActor.id },
            data: { person },
          });

          const eventCachedData = store.readQuery<{ event: IEvent }>({ query: FETCH_EVENT, variables: { uuid: this.event.uuid } });
          if (eventCachedData == null) return;
          const { event } = eventCachedData;
          if (event === null) {
            console.error('Cannot update event cache, because of null value.');
            return;
          }
          if (participation.role === ParticipantRole.NOT_APPROVED) {
            event.participantStats.notApproved = event.participantStats.notApproved - 1;
          } else {
            event.participantStats.going = event.participantStats.going - 1;
            event.participantStats.participant = event.participantStats.participant - 1;
          }
          store.writeQuery({ query: FETCH_EVENT, variables: { uuid: this.uuid }, data: { event } });
        },
      });
      if (data) {
        this.$buefy.notification.open({
          message: this.$t('You have cancelled your participation') as string,
          type: 'is-success',
          position: 'is-bottom-right',
          duration: 5000,
        });
      }
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

  async handleErrors(errors: GraphQLError) {
    if (errors[0].message.includes('not found') || errors[0].message.includes('has invalid value $uuid')) {
      await this.$router.push({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  get actorIsParticipant() {
    if (this.actorIsOrganizer) return true;

    return this.participations.length > 0 && this.participations[0].role === ParticipantRole.PARTICIPANT;
  }

  get actorIsOrganizer() {
    return this.participations.length > 0 && this.participations[0].role === ParticipantRole.CREATOR;
  }

  get endDate() {
    return this.event.endsOn !== null && this.event.endsOn > this.event.beginsOn ? this.event.endsOn : this.event.beginsOn;
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
    return `mailto:?to=&body=${this.event.url}${encodeURIComponent('\n\n')}${this.textDescription}&subject=${this.event.title}`;
  }

  get diasporaShareUrl(): string {
    return `https://share.diasporafoundation.org/?title=${encodeURIComponent(this.event.title)}&url=${encodeURIComponent(this.event.url)}`;
  }

  get textDescription(): string {
    const meta = document.querySelector("meta[property='og:description']");
    if (!meta) return '';
    const desc = meta.getAttribute('content') || '';
    return desc.substring(0, 1000);
  }

  get eventCapacityOK(): boolean {
    if (this.event.draft) return true;
    if (!this.event.options.maximumAttendeeCapacity) return true;
    return this.event.options.maximumAttendeeCapacity > this.event.participantStats.participant;
  }

  get numberOfPlacesStillAvailable(): number {
    if (this.event.draft) return this.event.options.maximumAttendeeCapacity;
    return this.event.options.maximumAttendeeCapacity - this.event.participantStats.participant;
  }

  urlToHostname(url: string): string|null {
    try {
      return (new URL(url)).hostname;
    } catch (e) {
      return null;
    }
  }

  get physicalAddress(): Address|null {
    if (!this.event.physicalAddress) return null;
    return new Address(this.event.physicalAddress);
  }
}
</script>
<style lang="scss" scoped>
  @import "../../variables";

  .fade-enter-active, .fade-leave-active {
    transition: opacity .5s;
  }
  .fade-enter, .fade-leave-to {
    opacity: 0;
  }

  .header-picture, .header-picture-default {
    height: 400px;
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
  }

  .header-picture-default {
    background-image: url('/img/mobilizon_default_card.png');
  }

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

        span:first-child {
          display: flex;

          span.icon {
            align-self: center;
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
      }

      div.map {
        height: 900px;
        width: 100%;
        padding: 25px 5px 0;
      }
    }

    span.online-address {
      display: flex;
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
    padding: 7.5px 10px 0;
    margin-bottom: 1rem;

    div.title-wrapper {
      display: flex;
      flex: 1 1 auto;

      div.title-and-informations {
        h1.title {
          font-weight: normal;
          word-break: break-word;
          font-size: 1.7em;
          margin-bottom: 0;
        }

        span small {
          &:not(:last-child):after {
            content: '⋅'
          }

          &:not(:first-child) {
            padding-left: 3px;
          }
        }
      }


      div.date-component {
        margin-right: 16px;
      }
    }

    .event-participation small {
      display: block;
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
        margin: 0 2px 4px;

        &.is-success {
            &::before {
                content: '#';
            }
            text-transform: uppercase;
            color: #111111;
        }
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

    @media screen and (min-width: 1216px) {
      background-repeat: no-repeat;
      background-size: 600px;
      background-position: 95% 101%;
      background-image: url('../../assets/texting.svg');
    }
    border-top: solid 1px #111;
    border-bottom: solid 1px #111;

    .description-content {
      /deep/ h1 {
        font-size: 2rem;
      }

      /deep/ h2 {
        font-size: 1.5rem;
      }

      /deep/ h3 {
        font-size: 1.25rem;
      }

      /deep/ ul {
        list-style-type: disc;
      }

      /deep/ li {
        margin: 10px auto 10px 2rem;
      }

      /deep/ blockquote {
        border-left: .2em solid #333;
        display: block;
        padding-left: 1em;
      }

      /deep/ p {
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

  .share {
    border-bottom: solid 1px #111;

    .diaspora span svg {
      height: 2rem;
      width: 2rem;
    }

    .columns {

      & > * {
        padding: 10rem 0;
      }

      h3 {
        display: block;
        color: $primary;
        font-size: 3rem;
        text-decoration: underline;
        text-decoration-color: $secondary;
        max-width: 20rem;
      }

      .column:first-child {
        h3 {
          margin: 0 auto 1rem;
          font-weight: normal;
        }

        small.maximumNumberOfPlacesWarning {
          margin: 0 auto 1rem;
          display: block;
        }
      }

      .column:last-child {

        h3 {
          margin-right: 0;
        }
      }

      .add-to-calendar {
        display: flex;

        h3 {
          margin-left: 0;
          cursor: pointer;
        }

        img {
          max-width: 400px;
        }

        &::before {
          content:"";
          background: #B3B3B2;
          position: absolute;
          bottom: 25%;
          left: 0;
          height: 40%;
          width: 1px;
        }
      }
    }
  }

  .more-events {
    margin: 50px auto;
  }
</style>
