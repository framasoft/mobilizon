<template>
  <v-container>
    <h1 class="welcome" v-if="$store.state.user">{{ $t("home.welcome", { 'username': this.displayed_name }) }}</h1>
    <h1 class="welcome" v-else>{{ $t("home.welcome_off", { 'username': $store.state.user.username}) }}</h1>
    <router-link :to="{ name: 'EventList' }">{{ $t('home.events') }}</router-link>
    <router-link v-if="$store.state.user === false" :to="{ name: 'Login' }">{{ $t('home.login') }}</router-link>
    <router-link v-if="$store.state.user === false" :to="{ name: 'Register' }">{{ $t('home.register') }}</router-link>
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
      user: null,
      searchTerm: null,
      location_field: {
        loading: false,
        search: null,
      },
      locations: [],
    };
  },
  mounted() {
    // this.fetchLocations();
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
