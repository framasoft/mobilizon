<template>
  <div>
    <section class="hero is-light is-bold" v-if="config && (!currentUser.id || !currentActor.id)">
        <div class="hero-body">
          <div class="container">
            <h1 class="title">{{ $t('Gather ⋅ Organize ⋅ Mobilize') }}</h1>
            <p class="subtitle">{{ $t('Join {instance}, a Mobilizon instance', { instance: config.name }) }}
            <p class="instance-description">{{ config.description }}</p>
            <!-- We don't invite to find other instances yet -->
            <!-- <p v-if="!config.registrationsOpen">
              {{ $t("This instance isn't opened to registrations, but you can register on other instances.") }}
            </p> -->
            <b-message type="is-danger" v-if="!config.registrationsOpen">
              {{ $t("Unfortunately, this instance isn't opened to registrations") }}
            </b-message>
            <div class="buttons">
              <b-button type="is-primary" tag="router-link" :to="{ name: RouteName.REGISTER }" v-if="config.registrationsOpen">
                {{ $t('Sign up') }}
              </b-button>
              <!-- We don't invite to find other instances yet -->
              <!-- <b-button v-else type="is-link" tag="a" href="https://joinmastodon.org">{{ $t('Find an instance') }}</b-button> -->
              <b-button type="is-text" tag="router-link" :to="{ name: RouteName.ABOUT }">{{ $t('Learn more about Mobilizon')}}</b-button>
            </div>
          </div>
        </div>
      </section>
    <div class="container section" v-if="config">
      <section v-if="currentActor.id">
        <b-message type="is-info" v-if="welcomeBack">
          {{ $t('Welcome back {username}!', { username: currentActor.displayName() }) }}
        </b-message>
        <b-message type="is-info" v-if="newRegisteredUser">
          {{ $t('Welcome to Mobilizon, {username}!', { username: currentActor.displayName() }) }}
        </b-message>
      </section>
      <section v-if="currentActor.id && goingToEvents.size > 0" class="container">
        <h3 class="title">
          {{ $t("Upcoming") }}
        </h3>
        <b-loading :active.sync="$apollo.loading"></b-loading>
        <div v-for="row of goingToEvents" class="upcoming-events" :key="row[0]">
          <span class="date-component-container" v-if="isInLessThanSevenDays(row[0])">
            <date-component :date="row[0]"></date-component>
            <h3 class="subtitle"
              v-if="isToday(row[0])">
              {{ $tc('You have one event today.', row[1].length, {count: row[1].length}) }}
            </h3>
            <h3 class="subtitle"
                v-else-if="isTomorrow(row[0])">
              {{ $tc('You have one event tomorrow.', row[1].length, {count: row[1].length}) }}
            </h3>
            <h3 class="subtitle"
                v-else-if="isInLessThanSevenDays(row[0])">
                {{ $tc('You have one event in {days} days.', row[1].length, {count: row[1].length, days: calculateDiffDays(row[0])}) }}
            </h3>
          </span>
          <div>
            <EventListCard
                    v-for="participation in row[1]"
                    v-if="isInLessThanSevenDays(row[0])"
                    :key="participation[1].id"
                    :participation="participation[1]"
            />
          </div>
        </div>
        <span class="view-all">
          <router-link :to=" { name: RouteName.MY_EVENTS }">{{ $t('View everything')}} >></router-link>
        </span>
      </section>
      <section v-if="currentActor && lastWeekEvents.length > 0">
        <h3 class="title">
          {{ $t("Last week") }}
        </h3>
        <b-loading :active.sync="$apollo.loading"></b-loading>
        <div>
            <EventListCard
                    v-for="participation in lastWeekEvents"
                    :key="participation.id"
                    :participation="participation"
                    :options="{ hideDate: false }"
            />
        </div>
      </section>
      <section class="events-featured">
        <h3 class="title">{{ $t('Featured events') }}</h3>
        <b-loading :active.sync="$apollo.loading"></b-loading>
        <div v-if="filteredFeaturedEvents.length > 0" class="columns is-multiline">
          <div class="column is-one-third-desktop" v-for="event in filteredFeaturedEvents.slice(0, 6)" :key="event.uuid">
            <EventCard
              :event="event"
            />
          </div>
        </div>
        <b-message v-else type="is-danger">
          {{ $t('No events found') }}
        </b-message>
      </section>
    </div>
  </div>
</template>

<script lang="ts">
import ngeohash from 'ngeohash';
import { FETCH_EVENTS } from '@/graphql/event';
import { Component, Vue } from 'vue-property-decorator';
import EventListCard from '@/components/Event/EventListCard.vue';
import EventCard from '@/components/Event/EventCard.vue';
import { CURRENT_ACTOR_CLIENT, LOGGED_USER_PARTICIPATIONS } from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import { ICurrentUser } from '@/types/current-user.model';
import { CURRENT_USER_CLIENT } from '@/graphql/user';
import { RouteName } from '@/router';
import { EventModel, IEvent, IParticipant, Participant, ParticipantRole } from '@/types/event.model';
import DateComponent from '@/components/Event/DateCalendarIcon.vue';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';

@Component({
  apollo: {
    events: {
      query: FETCH_EVENTS,
      fetchPolicy: 'no-cache', // Debug me: https://github.com/apollographql/apollo-client/issues/3030
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
      update: data => new Person(data.currentActor),
    },
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    config: {
      query: CONFIG,
    },
    currentUserParticipations: {
      query: LOGGED_USER_PARTICIPATIONS,
      variables() {
        const lastWeek = new Date();
        lastWeek.setDate(new Date().getDate() - 7);
        return {
          afterDateTime: lastWeek.toISOString(),
        };
      },
      update: (data) => {
        return data.loggedUser.participations.map(participation => new Participant(participation));
      },
      skip() {
        return this.currentUser.isLoggedIn === false;
      },
    },
  },
  components: {
    DateComponent,
    EventListCard,
    EventCard,
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // @ts-ignore
      title: this.instanceName,
      // all titles will be injected into this template
      titleTemplate: '%s | Mobilizon',
    };
  },
})
export default class Home extends Vue {
  events: IEvent[] = [];
  locations = [];
  city = { name: null };
  country = { name: null };
  currentUser!: ICurrentUser;
  currentActor!: IPerson;
  config!: IConfig;
  RouteName = RouteName;

  currentUserParticipations: IParticipant[] = [];

  // get displayed_name() {
  //   return this.loggedPerson && this.loggedPerson.name === null
  //     ? this.loggedPerson.preferredUsername
  //     : this.loggedPerson.name;
  // }

  get instanceName() {
    if (!this.config) return undefined;
    return this.config.name;
  }

  get welcomeBack() {
    return window.localStorage.getItem('welcome-back') === 'yes';
  }

  get newRegisteredUser() {
    return window.localStorage.getItem('new-registered-user') === 'yes';
  }

  mounted() {
    if (window.localStorage.getItem('welcome-back')) {
      window.localStorage.removeItem('welcome-back');
    }
    if (window.localStorage.getItem('new-registered-user')) {
      window.localStorage.removeItem('new-registered-user');
    }
  }

  isToday(date: Date) {
    return (new Date(date)).toDateString() === (new Date()).toDateString();
  }

  isTomorrow(date: string) :boolean {
    return this.isInDays(date, 1);
  }

  isInDays(date: string, nbDays: number) :boolean {
    return this.calculateDiffDays(date) === nbDays;
  }

  isBefore(date: string, nbDays: number) :boolean {
    return this.calculateDiffDays(date) < nbDays;
  }

  isAfter(date: string, nbDays: number) :boolean {
    return this.calculateDiffDays(date) >= nbDays;
  }

  isInLessThanSevenDays(date: string): boolean {
    return this.isBefore(date, 7);
  }

  calculateDiffDays(date: string): number {
    return Math.ceil(((new Date(date)).getTime() - (new Date()).getTime()) / 1000 / 60 / 60 / 24);
  }

  get goingToEvents(): Map<string, Map<string, IParticipant>> {
    const res = this.currentUserParticipations.filter(({ event, role }) => {
      return event.beginsOn != null &&
              this.isAfter(event.beginsOn.toDateString(), 0) &&
              this.isBefore(event.beginsOn.toDateString(), 7) &&
              role !== ParticipantRole.REJECTED;
    });
    res.sort(
            (a: IParticipant, b: IParticipant) => a.event.beginsOn.getTime() - b.event.beginsOn.getTime(),
    );

    return res.reduce((acc: Map<string, Map<string, IParticipant>>, participation: IParticipant) => {
      const day = (new Date(participation.event.beginsOn)).toDateString();
      const participations: Map<string, IParticipant> = acc.get(day) || new Map();
      participations.set(`${participation.event.uuid}${participation.actor.id}`, participation);
      acc.set(day, participations);
      return acc;
    },                new Map());
  }

  get lastWeekEvents() {
    const res = this.currentUserParticipations.filter(({ event, role }) => {
      return event.beginsOn != null && this.isBefore(event.beginsOn.toDateString(), 0) && role !== ParticipantRole.REJECTED;
    });
    res.sort(
          (a: IParticipant, b: IParticipant) => a.event.beginsOn.getTime() - b.event.beginsOn.getTime(),
      );
    return res;
  }

  get filteredFeaturedEvents() {
    if (!this.currentUser.isLoggedIn || !this.currentActor.id) return this.events;
    return this.events.filter(event => event.organizerActor && event.organizerActor.id !== this.currentActor.id);
  }

  geoLocalize() {
    const router = this.$router;
    const sessionCity = sessionStorage.getItem('City');

    if (sessionCity) {
      return router.push({ name: 'EventList', params: { location: sessionCity } });
    }

    navigator.geolocation.getCurrentPosition(
      pos => {
        const crd = pos.coords;

        const geoHash = ngeohash.encode(crd.latitude, crd.longitude, 11);
        sessionStorage.setItem('City', geoHash);
        router.push({ name: RouteName.EVENT_LIST, params: { location: geoHash } });
      },

      err => console.warn(`ERROR(${err.code}): ${err.message}`),

      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0,
      },
    );
  }

  getAddressData(addressData) {
    const geoHash = ngeohash.encode(
      addressData.latitude,
      addressData.longitude,
      11,
    );
    sessionStorage.setItem('City', geoHash);

    this.$router.push({ name: RouteName.EVENT_LIST, params: { location: geoHash } });
  }

  viewEvent(event) {
    this.$router.push({ name: RouteName.EVENT, params: { uuid: event.uuid } });
  }

  // ipLocation() {
  //   return this.city.name ? this.city.name : this.country.name;
  // }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
  @import "@/variables.scss";

  main > div > .container {
    background: $white;
  }

  .section {
    padding: 1rem 1.5rem;
  }

.search-autocomplete {
  border: 1px solid #dbdbdb;
  color: rgba(0, 0, 0, 0.87);
}

.events-featured {
  .columns {
    margin: 1rem auto 3rem;
  }
}

.date-component-container {
  display: flex;
  align-items: center;
  margin: 1.5rem auto;

  h3.subtitle {
    margin-left: 7px;
  }
}

    section.container {
        margin: auto auto 3rem;
    }

  span.view-all {
    display: block;
    margin-top: 2rem;
    text-align: right;

    a {
      text-decoration: underline;
    }
  }

  section.hero {
    margin-top: -3px;
    background: lighten($secondary, 20%);

    .column figure.image img {
      max-width: 400px;
    }

    .instance-description {
      margin-bottom: 1rem;
    }
  }
</style>
