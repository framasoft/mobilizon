<template>
  <v-container>
    <h1>{{ $t("event.list.title") }}</h1>

    <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
    <v-chip close v-model="locationChip" label color="pink" text-color="white" v-if="$router.currentRoute.params.location">
      <v-icon left>location_city</v-icon>{{ locationText }}
    </v-chip>
    <v-layout row wrap justify-space-around>
      <v-flex xs12 md3 v-for="event in events" :key="event.id">
        <v-card>
          <v-card-media v-if="event.image"
            class="white--text"
            height="200px"
            src="http://lorempixel.com/400/200/"
          >
            <v-container fill-height fluid>
              <v-layout fill-height>
                <v-flex xs12 align-end flexbox>
                  <span class="headline">{{ event.title }}</span>
                </v-flex>
              </v-layout>
            </v-container>
          </v-card-media>
          <v-card-title v-else primary-title>
            <div class="headline">{{ event.title }}</div>
          </v-card-title>
          <v-container>
              <!--<span class="grey&#45;&#45;text">{{ event.startDate | formatDate }} à <router-link :to="{name: 'EventList', params: {location: geocode(event.address.geo.latitude, event.address.geo.longitude, 10) }}">{{ event.address.addressLocality }}</router-link></span><br>-->
              <p><vue-markdown>{{ event.description }}</vue-markdown></p>
              <p v-if="event.organizer">Organisé par <router-link :to="{name: 'Account', params: {'id': event.organizer.id}}">{{ event.organizer.username }}</router-link></p>
          </v-container>
          <v-card-actions>
            <v-btn flat color="orange" @click="downloadIcsEvent(event)">Share</v-btn>
            <v-btn flat color="orange" @click="viewEvent(event.id)">Explore</v-btn>
            <v-btn flat color="red" @click="deleteEvent(event.id)">Delete</v-btn>
          </v-card-actions>
        </v-card>
      </v-flex>
    </v-layout>
    <router-link :to="{ name: 'CreateEvent' }" class="btn btn-default">Create</router-link>
  </v-container>
</template>

<script>
  import ngeohash from 'ngeohash';
  import VueMarkdown from 'vue-markdown';
  import eventFetch from '@/api/eventFetch';
  import VCardTitle from "vuetify/es5/components/VCard/VCardTitle";

  export default {
    name: 'EventList',
    components: {
      VCardTitle,
      VueMarkdown
    },
    data() {
      return {
        events: [],
        loading: true,
        locationChip: false,
        locationText: '',
      };
    },
    props: ['location'],
    created() {
      this.fetchData(this.$router.currentRoute.params.location);
    },
    watch: {
      locationChip(val) {
        if (val === false) {
          this.$router.push({name: 'EventList'});
        }
      }
    },
    beforeRouteUpdate(to, from, next) {
      this.fetchData(to.params.location);
      next();
    },
    methods: {
      geocode(lat, lon) {
        console.log({lat, lon});
        console.log(ngeohash.encode(lat, lon, 10));
        return ngeohash.encode(lat, lon, 10);
      },
      fetchData(location) {
        let queryString = '/events';
        if (location) {
          queryString += ('?geohash=' + location);
          const { latitude, longitude } = ngeohash.decode(location);
          this.locationText = latitude.toString() + ' : ' + longitude.toString();
        }
        this.locationChip = true;
        eventFetch(queryString, this.$store)
          .then(response => response.json())
          .then((response) => {
            this.loading = false;
            this.events = response.data;
          });
      },
      deleteEvent(id) {
        const router = this.$router;
        eventFetch('/events/' + id, this.$store, {'method': 'DELETE'})
          .then(() => router.push('/events'));
      },
      viewEvent(id) {
        this.$router.push({ name: 'Event', params: { id } })
      },
      downloadIcsEvent(event) {
        eventFetch('/events/' + event.id + '/export', this.$store, {responseType: 'arraybuffer'})
          .then((response) => response.text())
          .then(response => {
            const blob = new Blob([response],{type: 'text/calendar'});
            const link = document.createElement('a');
            link.href = window.URL.createObjectURL(blob);
            link.download = `${event.title}.ics`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
          })
      },
    },
  };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
