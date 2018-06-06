<template>
  <v-container>
    <v-layout row>
      <v-flex xs12 sm6 offset-sm3>
        <span v-if="error">Error : event not found</span>
        <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
        <v-card v-if="!loading && !error">
          <v-layout column class="media">
            <v-card-title>
              <v-btn icon @click="$router.go(-1)">
                <v-icon>chevron_left</v-icon>
              </v-btn>
              <v-spacer></v-spacer>
              <v-btn icon class="mr-3" v-if="event.organizer.id === $store.state.user.actor.id" :to="{ name: 'EditEvent', params: {id: event.id}}">
                <v-icon>edit</v-icon>
              </v-btn>
              <v-menu bottom left>
                <v-btn icon slot="activator">
                  <v-icon>more_vert</v-icon>
                </v-btn>
                <v-list>
                  <v-list-tile @click="downloadIcsEvent()">
                    <v-list-tile-title>Download</v-list-tile-title>
                  </v-list-tile>
                  <v-list-tile @click="deleteEvent()" v-if="$store.state.user.actor.id === event.organizer.id">
                    <v-list-tile-title>Delete</v-list-tile-title>
                  </v-list-tile>
                </v-list>
              </v-menu>
            </v-card-title>
              <v-container grid-list-md text-xs-center>
                  <v-card-media
                          src="https://picsum.photos/600/400/"
                          height="200px"
                  >

                  </v-card-media>
                  <v-layout row wrap>
                      <v-flex xs6>
            <v-spacer></v-spacer>
              <span class="subheading grey--text">{{ event.begins_on | formatDay }}</span>
              <h1 class="display-2">{{ event.title }}</h1>
              <div>
                  <router-link :to="{name: 'Account', params: { name: event.organizer.username } }">
                      <v-avatar size="25px">
                          <img class="img-circle elevation-7 mb-1"
                               :src="event.organizer.avatar"
                          >
                      </v-avatar>
                  </router-link>
                  <span v-if="event.organizer">Organisé par {{ event.organizer.display_name }}</span>
              </div>
                          <p>
                              <vue-markdown :source="event.description" />
                          </p>
              <!--<p><router-link :to="{ name: 'Account', params: {id: event.organizer.id} }"><span class="grey&#45;&#45;text">{{ event.organizer.username }}</span></router-link> organises {{ event.title }} <span v-if="event.address.addressLocality">in {{ event.address.addressLocality }}</span> on the {{ event.startDate | formatDate }}.</p>
              <v-card-text v-if="event.description"><vue-markdown :source="event.description"></vue-markdown></v-card-text>-->
                      </v-flex>
                      <v-flex xs6>
                          <v-card-actions>
                              <v-btn color="success" v-if="!event.participants.map(participant => participant.id).includes($store.state.user.actor.id)" @click="joinEvent" class="btn btn-primary"><v-icon>check</v-icon> Join</v-btn>
                              <v-btn v-if="event.participants.map(participant => participant.id).includes($store.state.user.actor.id)" @click="leaveEvent" class="btn btn-primary">Leave</v-btn>
                          </v-card-actions>
                      </v-flex>
                  </v-layout>
              </v-container>
          <v-container fluid grid-list-md>
            <v-subheader>Membres</v-subheader>
            <v-layout row>
              <v-flex xs2 v-for="actor in event.participants" :key="actor.uuid">
                <router-link :to="{name: 'Account', params: { name: actor.username }}">
                  <v-avatar size="75px">
                    <img v-if="!actor.avatar"
                         class="img-circle elevation-7 mb-1"
                         src="https://picsum.photos/125/125/"
                    >
                    <img v-else
                         class="img-circle elevation-7 mb-1"
                         :src="actor.avatar"
                    >
                  </v-avatar>
                </router-link>
                <span>{{ actor.username }}</span>
              </v-flex>
                <span v-if="event.participants.length === 0">No participants yet.</span>
            </v-layout>
          </v-container>
          </v-layout>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
  import eventFetch from '@/api/eventFetch';
  import VueMarkdown from 'vue-markdown';

  export default {
    name: 'Home',
    components: {
      VueMarkdown,
    },
    data() {
      return {
        loading: true,
        error: false,
        event: {
          name: '',
          slug: '',
          title: '',
          uuid: this.uuid,
          description: '',
          organizer: {
            id: null,
            username: null,
          },
          participants: [],
        },
      };
    },
    methods: {
      deleteEvent() {
        const router = this.$router;
        eventFetch(`/events/${this.uuid}`, this.$store, { method: 'DELETE' })
          .then(() => router.push({'name': 'EventList'}));
      },
      fetchData() {
        eventFetch(`/events/${this.uuid}`, this.$store)
          .then(response => response.json())
          .then((data) => {
            this.loading = false;
            this.event = data.data;
          }).catch((res) => {
            Promise.resolve(res).then((data) => {
              console.log(data);
              this.error = true;
              this.loading = false;
          })
        });
      },
      joinEvent() {
        eventFetch(`/events/${this.uuid}/join`, this.$store)
          .then(response => response.json())
          .then((data) => {
            console.log(data);
          });
      },
      leaveEvent() {
        eventFetch(`/events/${this.uuid}/leave`, this.$store)
          .then(response => response.json())
          .then((data) => {
            console.log(data);
          });
      },
      downloadIcsEvent() {
        eventFetch(`/events/${this.uuid}/ics`, this.$store, {responseType: 'arraybuffer'})
          .then((response) => response.text())
          .then(response => {
            const blob = new Blob([response],{type: 'text/calendar'});
            const link = document.createElement('a');
            link.href = window.URL.createObjectURL(blob);
            link.download = `${this.event.title}.ics`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
          })
      },
    },
    props: {
        uuid: {
            type: String,
            required: true,
        },
    },
    created() {
      this.fetchData();
    },
  };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
