<template>
  <v-layout row>
    <v-flex xs12 sm6 offset-sm3>
      <v-progress-circular v-if="$apollo.loading" indeterminate color="primary"></v-progress-circular>
      <div>{{ event }}</div>
      <v-card v-if="event">
        <!-- <v-img
          src="https://picsum.photos/600/400/"
          height="200px"
        >
          <v-container fill-height fluid>
            <v-layout fill-height>
              <v-flex xs12 align-end flexbox>
                <v-card-title>
                  <v-btn icon @click="$router.go(-1)" class="white--text">
                    <v-icon>chevron_left</v-icon>
                  </v-btn>
                  <v-spacer></v-spacer>
                  <v-btn icon class="mr-3 white--text" v-if="actorIsOrganizer()" :to="{ name: 'EditEvent', params: {uuid: event.uuid}}">
                    <v-icon>edit</v-icon>
                  </v-btn>
                  <v-menu bottom left>
                    <v-btn icon slot="activator" class="white--text">
                      <v-icon>more_vert</v-icon>
                    </v-btn>
                    <v-list>
                      <v-list-tile @click="downloadIcsEvent()">
                        <v-list-tile-title>Download</v-list-tile-title>
                      </v-list-tile>
                      <v-list-tile @click="deleteEvent()" v-if="actorIsOrganizer()">
                        <v-list-tile-title>Delete</v-list-tile-title>
                      </v-list-tile>
                    </v-list>
                  </v-menu>
                </v-card-title>
              </v-flex>
            </v-layout>
          </v-container>
        </v-img> -->
        <v-container grid-list-md>
          <v-layout row wrap>
            <v-flex md10>
              <v-spacer></v-spacer>
              <span class="subheading grey--text">{{ event.begins_on | formatDay }}</span>
              <h1 class="display-1">{{ event.title }}</h1>
              <div>
                <!-- <router-link :to="{name: 'Account', params: { name: event.organizerActor.preferredUsername } }">
                    <v-avatar size="25px">
                        <img class="img-circle elevation-7 mb-1"
                              :src="event.organizer_actor.avatarUrl"
                        >
                    </v-avatar>
                </router-link> -->
                <!-- <span v-if="event.organizerActor">Organisé par {{ event.organizerActor.name ? event.organizerActor.name : event.organizerActor.preferredUsername }}</span> -->
              </div>
              <!-- <p><router-link :to="{ name: 'Account', params: {id: event.organizer.id} }"><span class="grey&#45;&#45;text">{{ event.organizer.username }}</span></router-link> organises {{ event.title }} <span v-if="event.address.addressLocality">in {{ event.address.addressLocality }}</span> on the {{ event.startDate | formatDate }}.</p> -->
              <v-card-text v-if="event.description">
                <vue-markdown :source="event.description"></vue-markdown>
              </v-card-text>
            </v-flex>
            <!-- <v-flex md2>
              <p v-if="actorIsOrganizer()">
                Vous êtes organisateur de cet événement.
              </p>
              <div v-else>
                <p v-if="actorIsParticipant()">
                  Vous avez annoncé aller à cet événement.
                </p>
                <p v-else>Vous y allez ?
                  <span class="text--darken-2 grey--text">{{ event.participants.length }} personnes y vont.</span>
                </p>
              </div>
              <v-card-actions v-if="!actorIsOrganizer()">
                <v-btn v-if="!actorIsParticipant()" @click="joinEvent" color="success"><v-icon>check</v-icon> Join</v-btn>
                <v-btn v-if="actorIsParticipant()" @click="leaveEvent" color="error">Leave</v-btn>
              </v-card-actions>
            </v-flex> -->
          </v-layout>
        </v-container>
        <v-divider></v-divider>
        <v-container>
          <v-layout row wrap>
            <v-flex xs12 md4 order-md1>
              <v-layout
                column
                fill-height
              >
                <v-list two-line>
                  <v-list-tile>
                    <v-list-tile-action>
                      <v-icon color="indigo">access_time</v-icon>
                    </v-list-tile-action>

                    <v-list-tile-content>
                      <v-list-tile-title>{{ event.begins_on | formatDate }}</v-list-tile-title>
                      <v-list-tile-sub-title>{{ event.ends_on | formatDate }}</v-list-tile-sub-title>
                    </v-list-tile-content>
                  </v-list-tile>

                  <v-divider inset></v-divider>

                  <v-list-tile>
                    <v-list-tile-action>
                      <v-icon color="indigo">place</v-icon>
                    </v-list-tile-action>

                    <v-list-tile-content>
                      <v-list-tile-title><span v-if="event.address_type === 'physical'">
                      {{ event.physical_address.streetAddress }}
                    </span></v-list-tile-title>
                      <v-list-tile-sub-title>Mobile</v-list-tile-sub-title>
                    </v-list-tile-content>
                  </v-list-tile>
                </v-list>
              </v-layout>
            </v-flex>
            <v-flex md8 xs12>
              <p>
              <h2>Details</h2>
              <vue-markdown :source="event.description" v-if="event.description" :toc-first-level="3"></vue-markdown>
              </p>
              <v-subheader>Participants</v-subheader>
              <!-- <v-flex md2 v-for="participant in event.participants" :key="participant.actor.uuid">
                <router-link :to="{name: 'Account', params: { name: participant.actor.preferredUsername }}">
                  <v-card>
                    <v-avatar size="75px">
                      <img v-if="!participant.actor.avatarUrl"
                          class="img-circle elevation-7 mb-1"
                          src="https://picsum.photos/125/125/"
                      >
                      <img v-else
                          class="img-circle elevation-7 mb-1"
                          :src="participant.actor.avatarUrl"
                      >
                    </v-avatar>
                    <v-card-title>
                      <span>{{ participant.actor.preferredUsername }}</span>
                    </v-card-title>
                  </v-card>
                </router-link>
              </v-flex> -->
            </v-flex>
            <span v-if="event.participants.length === 0">No participants yet.</span>
          </v-layout>
        </v-container>
      </v-card>
    </v-flex>
  </v-layout>
</template>

<script lang="ts">
  import { FETCH_EVENT } from '@/graphql/event';
  import { Component, Prop, Vue } from 'vue-property-decorator';
  import VueMarkdown from 'vue-markdown';

  @Component({
    components: {
      VueMarkdown,
    },
    apollo: {
      event: {
        query: FETCH_EVENT,
        variables() {
          return {
            uuid: this.uuid,
          };
        },
      },
      // loggedActor: {
      //   query: LOGGED_ACTOR,
      // }
    },
  })
  export default class Event extends Vue {
    @Prop({ type: String, required: true }) uuid!: string;

    event = {
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
    };

    deleteEvent() {
      const router = this.$router;
      // FIXME: remove eventFetch
      // eventFetch(`/events/${this.uuid}`, this.$store, { method: 'DELETE' })
      //   .then(() => router.push({ name: 'EventList' }));
    }

    joinEvent() {
      // FIXME: remove eventFetch
      // eventFetch(`/events/${this.uuid}/join`, this.$store, { method: 'POST' })
      //   .then(response => response.json())
      //   .then((data) => {
      //     console.log(data);
      //   });
    }

    leaveEvent() {
      // FIXME: remove eventFetch
      // eventFetch(`/events/${this.uuid}/leave`, this.$store)
      //   .then(response => response.json())
      //   .then((data) => {
      //     console.log(data);
      //   });
    }

    downloadIcsEvent() {
      // FIXME: remove eventFetch
      // eventFetch(`/events/${this.uuid}/ics`, this.$store, { responseType: 'arraybuffer' })
      //   .then(response => response.text())
      //   .then((response) => {
      //     const blob = new Blob([ response ], { type: 'text/calendar' });
      //     const link = document.createElement('a');
      //     link.href = window.URL.createObjectURL(blob);
      //     link.download = `${this.event.title}.ics`;
      //     document.body.appendChild(link);
      //     link.click();
      //     document.body.removeChild(link);
      //   });
    }

    // actorIsParticipant() {
    //   return this.loggedActor && this.event.participants.map(participant => participant.actor.preferredUsername).includes(this.loggedActor.preferredUsername) || this.actorIsOrganizer();
    // }
    //
    // actorIsOrganizer() {
    //   return this.loggedActor && this.loggedActor.preferredUsername === this.event.organizer.preferredUsername;
    // }
  }
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
  .v-card__media__background {
    filter: contrast(0.4);
  }
</style>
