<template>
  <v-container>
    <v-img
      :gradient="gradient"
      src="https://picsum.photos/1200/900"
      dark
      height="300"
      v-if="!user"
    >
      <v-container fill-height>
        <v-layout align-center>
          <v-flex text-xs-center>
            <h1 class="display-3">Find events you like</h1>
            <h2>Share it with Mobilizon</h2>
            <v-btn :to="{ name: 'Register' }">
              <translate>Register</translate>
            </v-btn>
          </v-flex>
        </v-layout>
      </v-container>
    </v-img>
    <v-layout v-else>
      <v-flex xs12 sm8 offset-sm2>
        <v-layout row wrap>
          <v-flex xs12 sm6>
            <h1>
              <translate :translate-params="{username: actor.preferredUsername}">Welcome back %{username}</translate>
            </h1>
          </v-flex>
          <v-flex xs12 sm6>
            <v-layout align-center>
              <span class="events-nearby title">Events nearby </span>
              <v-text-field
                solo
                append-icon="place"
                :value="ipLocation()"
              ></v-text-field>
            </v-layout>
          </v-flex>
        </v-layout>
        <div v-if="$apollo.loading">
          Still loading
        </div>
        <v-card v-if="events.length > 0">
          <v-layout row wrap>
            <v-flex md4 v-for="event in events" :key="event.uuid">
              <v-card :to="{ name: 'Event', params:{ uuid: event.uuid } }">
                <v-img v-if="!event.image"
                       class="white--text"
                       height="200px"
                       src="https://picsum.photos/g/400/200/"
                >
                  <v-container fill-height fluid>
                    <v-layout fill-height>
                      <v-flex xs12 align-end flexbox>
                        <span class="headline black--text">{{ event.title }}</span>
                      </v-flex>
                    </v-layout>
                  </v-container>
                </v-img>
                <v-card-title primary-title>
                  <div>
                    <span class="grey--text">{{ event.begins_on | formatDay }}</span><br>
                    <router-link :to="{name: 'Account', params: { name: event.organizerActor.preferredUsername } }">
                      <v-avatar size="25px">
                        <img class="img-circle elevation-7 mb-1"
                             :src="event.organizerActor.avatarUrl"
                        >
                      </v-avatar>
                    </router-link>
                    <span v-if="event.organizerActor">Organisé par {{ event.organizerActor.name ? event.organizerActor.name : event.organizerActor.preferredUsername }}</span>
                  </div>
                </v-card-title>
              </v-card>
            </v-flex>
          </v-layout>
        </v-card>
        <v-alert v-else :value="true" type="error">
          No events found
        </v-alert>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script lang="ts">
  import ngeohash from 'ngeohash';
  import { AUTH_USER_ACTOR, AUTH_USER_ID } from '@/constants';
  import { FETCH_EVENTS } from '@/graphql/event';
  import { Component, Vue } from 'vue-property-decorator';

  @Component({
    apollo: {
      events: {
        query: FETCH_EVENTS,
      },
    },
  })
  export default class Home extends Vue {
    gradient = 'to top right, rgba(63,81,181, .7), rgba(25,32,72, .7)';
    searchTerm = null;
    location_field = {
      loading: false,
      search: null,
    };
    events = [];
    locations = [];
    city = { name: null };
    country = { name: null };
    // FIXME: correctly parse local storage
    actor = JSON.parse(localStorage.getItem(AUTH_USER_ACTOR) || '{}');
    user = localStorage.getItem(AUTH_USER_ID);

    get displayed_name() {
      return this.actor.name === null ? this.actor.preferredUsername : this.actor.name;
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
      const sessionCity = sessionStorage.getItem('City')
      if (sessionCity) {
        router.push({ name: 'EventList', params: { location: sessionCity } });
      } else {
        navigator.geolocation.getCurrentPosition((pos) => {
          const crd = pos.coords;

          const geohash = ngeohash.encode(crd.latitude, crd.longitude, 11);
          sessionStorage.setItem('City', geohash);
          router.push({ name: 'EventList', params: { location: geohash } });
        }, err => console.warn(`ERROR(${err.code}): ${err.message}`), {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0,
        });
      }
    }

    getAddressData(addressData) {
      const geohash = ngeohash.encode(addressData.latitude, addressData.longitude, 11);
      sessionStorage.setItem('City', geohash);
      this.$router.push({ name: 'EventList', params: { location: geohash } });
    }

    viewEvent(event) {
      this.$router.push({ name: 'Event', params: { uuid: event.uuid } });
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
    color: rgba(0, 0, 0, .87);
  }

  .events-nearby {
    margin-bottom: 25px;
  }
</style>
