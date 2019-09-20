<template>
  <div class="container" v-if="config">
    <section class="hero is-link" v-if="!currentUser.id || !currentActor">
      <div class="hero-body">
        <div>
          <h1 class="title">{{ config.name }}</h1>
          <h2 class="subtitle">{{ config.description }}</h2>
          <router-link class="button" :to="{ name: 'Register' }" v-if="config.registrationsOpen">
            {{ $t('Register') }}
          </router-link>
          <p v-else>
            {{ $t("This instance isn't opened to registrations, but you can register on other instances.") }}
          </p>
        </div>
      </div>
    </section>
    <section v-else>
      <h1>
        {{ $t('Welcome back {username}', {username: `@${currentActor.preferredUsername}`}) }}
      </h1>
    </section>
    <b-dropdown aria-role="list">
      <button class="button is-primary" slot="trigger">
        <span>{{ $t('Create') }}</span>
        <b-icon icon="menu-down"></b-icon>
      </button>
.organizerActor.id
      <b-dropdown-item aria-role="listitem">
        <router-link :to="{ name: RouteName.CREATE_EVENT }">{{ $t('Event') }}</router-link>
      </b-dropdown-item>
      <b-dropdown-item aria-role="listitem">
        <router-link :to="{ name: RouteName.CREATE_GROUP }">{{ $t('Group') }}</router-link>
      </b-dropdown-item>
    </b-dropdown>
    <section v-if="currentActor && goingToEvents.size > 0" class="container">
      <h3 class="title">
        {{ $t("Upcoming") }}
      </h3>
      <pre>{{ Array.from(goingToEvents.entries()) }}</pre>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div v-for="row in goingToEvents" class="upcoming-events">
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
        <div class="level">
          <EventListCard
                  v-for="participation in row[1]"
                  v-if="isInLessThanSevenDays(row[0])"
                  :key="participation[1].event.uuid"
                  :participation="participation[1]"
                  class="level-item"
          />
        </div>
      </div>
      <span class="view-all">
        <router-link :to=" { name: EventRouteName.MY_EVENTS }">{{ $t('View everything')}} >></router-link>
      </span>
    </section>
    <section v-if="currentActor && lastWeekEvents.length > 0">
      <h3 class="title">
        {{ $t("Last week") }}
      </h3>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div class="level">
          <EventListCard
                  v-for="participation in lastWeekEvents"
                  :key="participation.id"
                  :participation="participation"
                  class="level-item"
                  :options="{ hideDate: false }"
          />
      </div>
    </section>
    <section>
      <h3 class="events-nearby title">{{ $t('Events nearby you') }}</h3>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div v-if="events.length > 0" class="columns is-multiline">
        <div class="column is-one-third-desktop" v-for="event in events.slice(0, 6)" :key="event.uuid">
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
import { EventModel, IEvent, IParticipant, Participant } from '@/types/event.model';
import DateComponent from '@/components/Event/DateCalendarIcon.vue';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { EventRouteName } from '@/router/event';

@Component({
  apollo: {
    events: {
      query: FETCH_EVENTS,
      fetchPolicy: 'no-cache', // Debug me: https://github.com/apollographql/apollo-client/issues/3030
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
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
    EventListCard,
    EventCard,
  },
})
export default class Home extends Vue {
  events: Event[] = [];
  locations = [];
  city = { name: null };
  country = { name: null };
  currentUserParticipations: IParticipant[] = [];
  currentUser!: ICurrentUser;
  currentActor!: IPerson;
  config: IConfig = { description: '', name: '', registrationsOpen: false };
  RouteName = RouteName;
  EventRouteName = EventRouteName;

  // get displayed_name() {
  //   return this.loggedPerson && this.loggedPerson.name === null
  //     ? this.loggedPerson.preferredUsername
  //     : this.loggedPerson.name;
  // }

  async mounted() {
    const lastWeek = new Date();
    lastWeek.setDate(new Date().getDate() - 7);

    const { data } = await this.$apollo.query({
      query: LOGGED_USER_PARTICIPATIONS,
      variables: {
        afterDateTime: lastWeek.toISOString(),
      },
    });

    if (data) {
      this.currentUserParticipations = data.loggedUser.participations.map(participation => new Participant(participation));
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
    const res = this.currentUserParticipations.filter(({ event }) => {
      return event.beginsOn != null && this.isAfter(event.beginsOn.toDateString(), 0) && this.isBefore(event.beginsOn.toDateString(), 7);
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
    const res = this.currentUserParticipations.filter(({ event }) => {
      return event.beginsOn != null && this.isBefore(event.beginsOn.toDateString(), 0);
    });
    res.sort(
          (a: IParticipant, b: IParticipant) => a.event.beginsOn.getTime() - b.event.beginsOn.getTime(),
      );
    return res;
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
.search-autocomplete {
  border: 1px solid #dbdbdb;
  color: rgba(0, 0, 0, 0.87);
}

.events-nearby {
  margin: 25px auto;
}

.date-component-container {
  display: flex;
  align-items: center;
  margin: 1.5rem auto;

  h3.subtitle {
    margin-left: 7px;
  }
}

  .upcoming-events {
    .level {
      margin-left: 4rem;
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
</style>
