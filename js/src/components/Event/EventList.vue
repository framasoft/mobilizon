<template>
  <v-layout>
    <v-flex xs12 sm8 offset-sm2>
      <v-card>
        <h1>{{ $t('event.list.title') }}</h1>

        <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
        <v-chip close v-model="locationChip" label color="pink" text-color="white" v-if="$router.currentRoute.params.location">
          <v-icon left>location_city</v-icon>
          {{ locationText }}
        </v-chip>
        <v-container grid-list-sm fluid>
          <v-layout row wrap>
            <v-flex xs4 v-for="event in events" :key="event.id">
              <v-card>
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
                    <span v-if="event.organizer">Organisé par <router-link
                      :to="{name: 'Account', params: {'name': event.organizer.username}}">{{ event.organizer.username }}</router-link></span>
                  </div>
                </v-card-title>
                <v-card-actions>
                  <v-btn flat color="orange" @click="downloadIcsEvent(event)">Share</v-btn>
                  <v-btn flat color="orange" @click="viewEvent(event)">Explore</v-btn>
                  <v-btn flat color="red" @click="deleteEvent(event)">Delete</v-btn>
                </v-card-actions>
              </v-card>
            </v-flex>
          </v-layout>
        </v-container>
        <router-link :to="{ name: 'CreateEvent' }" class="btn btn-default">Create</router-link>
      </v-card>
    </v-flex>
  </v-layout>
</template>

<script lang="ts">
  import ngeohash from 'ngeohash';
  import VueMarkdown from 'vue-markdown';
  import VCardTitle from 'vuetify/es5/components/VCard/VCardTitle';
  import { Component, Prop, Vue, Watch } from 'vue-property-decorator';

  @Component({
    components: {
      VCardTitle: VCardTitle as any,
      VueMarkdown,
    },
  })
  export default class EventList extends Vue {
    @Prop(String) location!: string;

    events = [];
    loading = true;
    locationChip = false;
    locationText = '';

    created() {
      this.fetchData(this.$router.currentRoute.params[ 'location' ]);
    }

    beforeRouteUpdate(to, from, next) {
      this.fetchData(to.params.location);
      next();
    }

    @Watch('locationChip')
    onLocationChipChange(val) {
      if (val === false) {
        this.$router.push({ name: 'EventList' });
      }
    }

    geocode(lat, lon) {
      console.log({ lat, lon });
      console.log(ngeohash.encode(lat, lon, 10));
      return ngeohash.encode(lat, lon, 10);
    }

    fetchData(location) {
      let queryString = '/events';
      if (location) {
        queryString += (`?geohash=${location}`);
        const { latitude, longitude } = ngeohash.decode(location);
        this.locationText = `${latitude.toString()} : ${longitude.toString()}`;
      }
      this.locationChip = true;
      // FIXME: remove eventFetch
      // eventFetch(queryString, this.$store)
      //   .then(response => response.json())
      //   .then((response) => {
      //     this.loading = false;
      //     this.events = response.data;
      //     console.log(this.events);
      //   });
    }

    deleteEvent(event) {
      const router = this.$router;
      // FIXME: remove eventFetch
      // eventFetch(`/events/${event.uuid}`, this.$store, { method: 'DELETE' })
      //   .then(() => router.push('/events'));
    }

    viewEvent(event) {
      this.$router.push({ name: 'Event', params: { uuid: event.uuid } });
    }

    downloadIcsEvent(event) {
      // FIXME: remove eventFetch
      // eventFetch(`/events/${event.uuid}/ics`, this.$store, { responseType: 'arraybuffer' })
      //   .then(response => response.text())
      //   .then((response) => {
      //     const blob = new Blob([ response ], { type: 'text/calendar' });
      //     const link = document.createElement('a');
      //     link.href = window.URL.createObjectURL(blob);
      //     link.download = `${event.title}.ics`;
      //     document.body.appendChild(link);
      //     link.click();
      //     document.body.removeChild(link);
      //   });
    }

  };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
