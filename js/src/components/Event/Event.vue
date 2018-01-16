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
              <v-btn icon class="mr-3" v-if="event.organizer.id === $store.state.user.account.id" :to="{ name: 'EditEvent', params: {id: event.id}}">
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
                  <v-list-tile @click="deleteEvent()" v-if="$store.state.user.account.id === event.organizer.id">
                    <v-list-tile-title>Delete</v-list-tile-title>
                  </v-list-tile>
                </v-list>
              </v-menu>
            </v-card-title>
            <v-spacer></v-spacer>
            <div class="text-xs-center">
              <v-card-title class="pl-5 pt-5">
                <div class="display-1 pl-5 pt-5">{{ event.title }}</div>
              </v-card-title>
              <!--<p><router-link :to="{ name: 'Account', params: {id: event.organizer.id} }"><span class="grey&#45;&#45;text">{{ event.organizer.username }}</span></router-link> organises {{ event.title }} <span v-if="event.address.addressLocality">in {{ event.address.addressLocality }}</span> on the {{ event.startDate | formatDate }}.</p>
              <v-card-text v-if="event.description"><vue-markdown :source="event.description"></vue-markdown></v-card-text>-->
            </div>
          <v-container fluid grid-list-md>
            <v-subheader>Membres</v-subheader>
            <v-layout row>
              <v-flex xs2>
                <router-link :to="{name: 'Account', params: {'id': event.organizer.id}}">
                  <v-avatar size="75px">
                    <img v-if="!event.organizer.avatarRemoteUrl"
                         class="img-circle elevation-7 mb-1"
                         src="http://lorempixel.com/125/125/"
                    >
                    <img v-else
                         class="img-circle elevation-7 mb-1"
                         :src="event.organizer.avatarRemoteUrl"
                    >
                  </v-avatar>
                </router-link>
                Organisateur <span>{{ event.organizer.username }}</span>
              </v-flex>
              <v-flex xs2 v-for="account in event.participants" :key="account.id">
                <router-link :to="{name: 'Account', params: {'id': account.id}}">
                  <v-avatar size="75px">
                    <img v-if="!account.avatarRemoteUrl"
                         class="img-circle elevation-7 mb-1"
                         src="http://lorempixel.com/125/125/"
                    >
                    <img v-else
                         class="img-circle elevation-7 mb-1"
                         :src="account.avatarRemoteUrl"
                    >
                  </v-avatar>
                </router-link>
                <span>{{ account.username }}</span>
              </v-flex>
            </v-layout>
          </v-container>
          <v-card-actions>
            <button v-if="!event.participants.map(participant => participant.id).includes($store.state.user.account.id)" @click="joinEvent" class="btn btn-primary">Join</button>
            <button v-if="event.participants.map(participant => participant.id).includes($store.state.user.account.id)" @click="leaveEvent" class="btn btn-primary">Leave</button>
            <button @click="deleteEvent" class="btn btn-danger">Delete</button>
          </v-card-actions>
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
          id: this.id,
          title: '',
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
        eventFetch(`/events/${this.id}`, this.$store, { method: 'DELETE' })
          .then(() => router.push({'name': 'EventList'}));
      },
      fetchData() {
        eventFetch(`/events/${this.id}`, this.$store)
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
        eventFetch(`/events/${this.id}/join`, this.$store)
          .then(response => response.json())
          .then((data) => {
            console.log(data);
          });
      },
      leaveEvent() {
        eventFetch(`/events/${this.id}/leave`, this.$store)
          .then(response => response.json())
          .then((data) => {
            console.log(data);
          });
      },
      downloadIcsEvent() {
        eventFetch('/events/' + this.event.id + '/ics', this.$store, {responseType: 'arraybuffer'})
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
    props: ['id'],
    created() {
      this.fetchData();
    },
  };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
