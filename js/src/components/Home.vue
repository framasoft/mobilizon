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
      <v-layout v-else>
          <v-flex xs12 sm8 offset-sm2>
            <v-layout row wrap>
                <v-flex xs12 sm6>
                  <h1>Welcome back {{ $store.state.defaultActor.username }}</h1>
                </v-flex>
                <v-flex xs12 sm6>
                <v-layout align-center>
                  <span class="events-nearby title">Events nearby </span><v-text-field
                    solo
                    append-icon="place"
                    :value="ipLocation()"
                  ></v-text-field>
                </v-layout>
              </v-flex>
            </v-layout>
              <v-card v-if="events.length > 0">
                <v-layout row wrap>
                    <v-flex md4 v-for="event in events" :key="event.uuid">
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
                                    <span class="grey--text">{{ event.begins_on | formatDay }}</span><br>
                                    <router-link :to="{name: 'Account', params: { name: event.organizer.username } }">
                                        <v-avatar size="25px">
                                            <img class="img-circle elevation-7 mb-1"
                                                :src="event.organizer.avatar"
                                            >
                                        </v-avatar>
                                    </router-link>
                                    <span v-if="event.organizer">Organisé par {{ event.organizer.display_name ? event.organizer.display_name : event.organizer.username }}</span>
                                </div>
                            </v-card-title>
                        </v-card>
                    </v-flex>
                </v-layout>
              </v-card>
              <v-alert v-else :value="true" type="info">
                No events found nearby {{ ipLocation() }}
              </v-alert>
          </v-flex>
      </v-layout>
  </v-container>
</template>

<script>

import ngeohash from 'ngeohash';
import eventFetch from "../api/eventFetch";

export default {
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
      city: {name: null},
      country: {name: null},
    };
  },
  created() {
    this.fetchData();
  },
  computed: {
    displayed_name() {
      return this.$store.state.defaultActor.display_name === null ? this.$store.state.defaultActor.username : this.$store.state.defaultActor.display_name
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
          this.city = response.city;
          this.country = response.country;
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
    ipLocation() {
      return this.city.name ? this.city.name : this.country.name;
    }
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
  .search-autocomplete {
    border: 1px solid #dbdbdb;
    color: rgba(0,0,0,.87);
  }

  .events-nearby {
    margin-bottom: 25px;
  }
</style>
