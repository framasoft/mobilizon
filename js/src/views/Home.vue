<template>
  <div class="container">
    <section class="hero is-link" v-if="!currentUser.id || !loggedPerson">
      <div class="hero-body">
        <div class="container">
          <h1 class="title">{{ config.name }}</h1>
          <h2 class="subtitle">{{ config.description }}</h2>
          <router-link class="button" :to="{ name: 'Register' }" v-if="config.registrationsOpen">
            <translate>Register</translate>
          </router-link>
          <p v-else>
            <translate>This instance isn't opened to registrations, but you can register on other instances.</translate>
          </p>
        </div>
      </div>
    </section>
    <section v-else>
      <h1>
        <translate
          :translate-params="{username: loggedPerson.preferredUsername}"
        >Welcome back %{username}</translate>
      </h1>
    </section>
    <b-dropdown aria-role="list">
      <button class="button is-primary" slot="trigger">
        <span>Create</span>
        <b-icon icon="menu-down"></b-icon>
      </button>

      <b-dropdown-item aria-role="listitem">
        <router-link :to="{ name: RouteName.CREATE_EVENT }">Event</router-link>
      </b-dropdown-item>
      <b-dropdown-item aria-role="listitem">
        <router-link :to="{ name: RouteName.CREATE_GROUP }">Group</router-link>
      </b-dropdown-item>
      <b-dropdown-item aria-role="listitem">Something else</b-dropdown-item>
    </b-dropdown>
    <section v-if="loggedPerson" class="container">
      <span class="events-nearby title"><translate>Events you're going at</translate></span>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div v-if="goingToEvents.size > 0" v-for="row in Array.from(goingToEvents.entries())">
        <!--   Iterators will be supported in v-for with VueJS 3     -->
        <date-component :date="row[0]"></date-component>
          <h3 class="subtitle"
            v-if="isToday(row[0])"
            v-translate="{count: row[1].length}"
            :translate-n="row[1].length"
            translate-plural="You have %{ count } events today"
          >
                  You have one event today.
          </h3>
          <h3 class="subtitle"
              v-else-if="isTomorrow(row[0])"
              v-translate="{count: row[1].length}"
              :translate-n="row[1].length"
              translate-plural="You have %{ count } events tomorrow"
          >
              You have one event tomorrow.
          </h3>
          <h3 class="subtitle"
              v-else
              v-translate="{count: row[1].length, days: calculateDiffDays(row[0])}"
              :translate-n="row[1].length"
              translate-plural="You have %{ count } events in %{ days } days"
          >
              You have one event in %{ days } days.
          </h3>
        <div class="columns">
          <EventCard
                  v-for="event in row[1]"
                  :key="event.uuid"
                  :event="event"
                  :options="{loggedPerson: loggedPerson}"
                  class="column is-one-quarter-desktop is-half-mobile"
          />
        </div>
      </div>
      <b-message v-else type="is-danger">
        <translate>You're not going to any event yet</translate>
      </b-message>
    </section>
    <section class="container">
      <h3 class="events-nearby title"><translate>Events nearby you</translate></h3>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div v-if="events.length > 0" class="columns is-multiline">
        <div class="column is-one-third-desktop" v-for="event in events.slice(0, 6)" :key="event.uuid">
          <EventCard
            :event="event"
          />
        </div>
      </div>
      <b-message v-else type="is-danger">
        <translate>No events found</translate>
      </b-message>
    </section>
  </div>
</template>

<script lang="ts">
import ngeohash from 'ngeohash';
import { FETCH_EVENTS } from '@/graphql/event';
import { Component, Vue } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { LOGGED_PERSON_WITH_GOING_TO_EVENTS } from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import { ICurrentUser } from '@/types/current-user.model';
import { CURRENT_USER_CLIENT } from '@/graphql/user';
import { RouteName } from '@/router';
import { IEvent } from '@/types/event.model';
import DateComponent from '@/components/Event/DateCalendarIcon.vue';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';

@Component({
  apollo: {
    events: {
      query: FETCH_EVENTS,
      fetchPolicy: 'no-cache', // Debug me: https://github.com/apollographql/apollo-client/issues/3030
    },
    loggedPerson: {
      query: LOGGED_PERSON_WITH_GOING_TO_EVENTS,
    },
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    config: {
      query: CONFIG,
    },
  },
  components: {
    DateComponent,
    EventCard,
  },
})
export default class Home extends Vue {
  events: Event[] = [];
  locations = [];
  city = { name: null };
  country = { name: null };
  loggedPerson: IPerson = new Person();
  currentUser!: ICurrentUser;
  config: IConfig = { description: '', name: '', registrationsOpen: false };
  RouteName = RouteName;

  // get displayed_name() {
  //   return this.loggedPerson && this.loggedPerson.name === null
  //     ? this.loggedPerson.preferredUsername
  //     : this.loggedPerson.name;
  // }

  isToday(date: string) {
    return (new Date(date)).toDateString() === (new Date()).toDateString();
  }

  isTomorrow(date: string) :boolean {
    return this.isInDays(date, 1);
  }

  isInDays(date: string, nbDays: number) :boolean {
    return this.calculateDiffDays(date) === nbDays;
  }

  isBefore(date: string, nbDays: number) :boolean {
    return this.calculateDiffDays(date) > nbDays;
  }

  // FIXME: Use me
  isInLessThanSevenDays(date: string): boolean {
    return this.isInDays(date, 7);
  }

  calculateDiffDays(date: string): number {
    const dateObj = new Date(date);
    return Math.ceil((dateObj.getTime() - (new Date()).getTime()) / 1000 / 60 / 60 / 24);
  }

  get goingToEvents(): Map<string, IEvent[]> {
    const res = this.$data.loggedPerson.goingToEvents.filter((event) => {
      return event.beginsOn != null && this.isBefore(event.beginsOn, 0);
    });
    res.sort(
            (a: IEvent, b: IEvent) => new Date(a.beginsOn) > new Date(b.beginsOn),
    );
    return res.reduce((acc: Map<string, IEvent[]>, event: IEvent) => {
      const day = (new Date(event.beginsOn)).toDateString();
      const events: IEvent[] = acc.get(day) || [];
      events.push(event);
      acc.set(day, events);
      return acc;
    },                new Map());
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
<style scoped>
.search-autocomplete {
  border: 1px solid #dbdbdb;
  color: rgba(0, 0, 0, 0.87);
}

.events-nearby {
  margin: 25px auto;
}
</style>
