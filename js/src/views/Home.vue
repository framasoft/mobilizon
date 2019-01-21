<template>
  <div>
    <section class="hero is-link" v-if="!currentUser.id">
      <div class="hero-body">
        <div class="container">
          <h1 class="title">Find events you like</h1>
          <h2 class="subtitle">Share them with Mobilizon</h2>
          <router-link class="button" :to="{ name: 'Register' }">
            <translate>Register</translate>
          </router-link>
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
    <section>
      <span class="events-nearby title">Events nearby you</span>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div v-if="events.length > 0" class="columns is-multiline">
        <EventCard
          v-for="event in events"
          :key="event.uuid"
          :event="event"
          class="column is-one-quarter-desktop is-half-mobile"
        />
      </div>
      <b-message v-else type="is-danger">
        <translate>No events found</translate>
      </b-message>
    </section>
  </div>
</template>

<script lang="ts">
import ngeohash from "ngeohash";
import { AUTH_USER_ACTOR, AUTH_USER_ID } from "@/constants";
import { FETCH_EVENTS } from "@/graphql/event";
import { Component, Vue } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { LOGGED_PERSON } from "@/graphql/actor";
import { IPerson } from "../types/actor.model";
import { ICurrentUser } from "@/types/current-user.model";
import { CURRENT_USER_CLIENT } from "@/graphql/user";

@Component({
  apollo: {
    events: {
      query: FETCH_EVENTS,
      fetchPolicy: "no-cache" // Debug me: https://github.com/apollographql/apollo-client/issues/3030
    },
    loggedPerson: {
      query: LOGGED_PERSON
    },
    currentUser: {
      query: CURRENT_USER_CLIENT
    }
  },
  components: {
    EventCard
  }
})
export default class Home extends Vue {
  searchTerm = null;
  location_field = {
    loading: false,
    search: null
  };
  events = [];
  locations = [];
  city = { name: null };
  country = { name: null };
  // FIXME: correctly parse local storage
  loggedPerson!: IPerson;
  currentUser!: ICurrentUser;

  get displayed_name() {
    return this.loggedPerson.name === null
      ? this.loggedPerson.preferredUsername
      : this.loggedPerson.name;
  }

  fetchLocations() {
    // FIXME: remove eventFetch
    // eventFetch('/locations', this.$store)
    //   .then(response => (response.json()))
    //   .then((response) => {
    //     this.locations = response;
    //   });
  }

  geoLocalize() {
    const router = this.$router;
    const sessionCity = sessionStorage.getItem("City");
    if (sessionCity) {
      router.push({ name: "EventList", params: { location: sessionCity } });
    } else {
      navigator.geolocation.getCurrentPosition(
        pos => {
          const crd = pos.coords;

          const geohash = ngeohash.encode(crd.latitude, crd.longitude, 11);
          sessionStorage.setItem("City", geohash);
          router.push({ name: "EventList", params: { location: geohash } });
        },
        err => console.warn(`ERROR(${err.code}): ${err.message}`),
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        }
      );
    }
  }

  getAddressData(addressData) {
    const geohash = ngeohash.encode(
      addressData.latitude,
      addressData.longitude,
      11
    );
    sessionStorage.setItem("City", geohash);
    this.$router.push({ name: "EventList", params: { location: geohash } });
  }

  viewEvent(event) {
    this.$router.push({ name: "Event", params: { uuid: event.uuid } });
  }

  ipLocation() {
    return this.city.name ? this.city.name : this.country.name;
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.search-autocomplete {
  border: 1px solid #dbdbdb;
  color: rgba(0, 0, 0, 0.87);
}

.events-nearby {
  margin-bottom: 25px;
}
</style>
