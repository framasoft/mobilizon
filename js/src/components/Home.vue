<template>
  <v-container>
      <v-jumbotron
              :gradient="gradient"
              src="https://picsum.photos/1200/900"
              dark
              v-if="$store.state.user === false"
      >
          <v-container fill-height>
              <v-layout align-center>
                  <v-flex text-xs-center>
                      <h1 class="display-3">Find events you like</h1>
                      <h2>Share it with Eventos</h2>
                      <v-btn :to="{ name: 'Register' }">{{ $t("home.register") }}</v-btn>
                  </v-flex>
              </v-layout>
          </v-container>
      </v-jumbotron>
      <v-layout>
          <v-flex xs12 sm8 offset-sm2>
              <v-card>
      <v-layout row wrap>
          <v-flex xs4 v-for="event in events" :key="event.uuid">
              <v-card :to="{ name: 'Event', params:{ uuid: event.uuid } }">
                  <v-card-media v-if="!event.image"
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
                  </v-card-media>
                  <v-card-title primary-title>
                      <div>
                          <span class="grey--text">{{ event.begins_on | formatDate }}</span><br>
                          <router-link :to="{name: 'Account', params: { name: event.organizer.username } }">
                              <v-avatar size="25px">
                                  <img class="img-circle elevation-7 mb-1"
                                       :src="event.organizer.avatar"
                                  >
                              </v-avatar>
                          </router-link>
                          <span v-if="event.organizer">Organisé par {{ event.organizer.display_name }}</span>
                      </div>
                  </v-card-title>
              </v-card>
          </v-flex>
      </v-layout>
              </v-card>
          </v-flex>
      </v-layout>
    <v-layout row>
      <v-flex xs6>
        <v-btn large @click="geoLocalize"><v-icon>my_location</v-icon>Me géolocaliser</v-btn>
      </v-flex>
      <v-flex xs6>
        <vuetify-google-autocomplete
          id="map"
          append-icon="search"
          classname="form-control"
          placeholder="Start typing"
          enable-geolocation
          types="(cities)"
          v-on:placechanged="getAddressData"
        >
        </vuetify-google-autocomplete>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>

import VuetifyGoogleAutocomplete from 'vuetify-google-autocomplete';
import ngeohash from 'ngeohash';
import eventFetch from "../api/eventFetch";

export default {
  components: { VuetifyGoogleAutocomplete },
  name: 'Home',
  data() {
    return {
      gradient: 'to top right, rgba(63,81,181, .7), rgba(25,32,72, .7)',
      user: null,
      searchTerm: null,
      location_field: {
        loading: false,
        search: null,
      },
      locations: [],
      events: [],
    };
  },
  created() {
    this.fetchData();
  },
  computed: {
    displayed_name: function() {
      return this.$store.state.user.actor.display_name === null ? this.$store.state.user.actor.username : this.$store.state.user.actor.display_name
    },
  },
  methods: {
    fetchLocations() {
      eventFetch('/locations', this.$store)
        .then((response) => (response.json()))
        .then((response) => {
          this.locations = response;
        });
    },
    fetchData() {
      eventFetch('/events', this.$store)
        .then(response => response.json())
        .then((response) => {
          this.loading = false;
          this.events = response.data;
        });
    },
    geoLocalize() {
      const router = this.$router;
      if (sessionStorage.getItem('City')) {
        router.push({name: 'EventList', params: {location: localStorage.getItem('City')}})
      } else {
        navigator.geolocation.getCurrentPosition((pos) => {
          const crd = pos.coords;

          const geohash = ngeohash.encode(crd.latitude, crd.longitude, 11);
          sessionStorage.setItem('City', geohash);
          router.push({name: 'EventList', params: {location: geohash}});

        }, (err) => console.warn(`ERROR(${err.code}): ${err.message}`), {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        });
      }
    },
    getAddressData: function (addressData) {
      const geohash = ngeohash.encode(addressData.latitude, addressData.longitude, 11);
      sessionStorage.setItem('City', geohash);
      this.$router.push({name: 'EventList', params: {location: geohash}});
    },
    viewEvent(event) {
      this.$router.push({ name: 'Event', params: { uuid: event.uuid } })
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
  .search-autocomplete {
    border: 1px solid #dbdbdb;
    color: rgba(0,0,0,.87);
  }
</style>
