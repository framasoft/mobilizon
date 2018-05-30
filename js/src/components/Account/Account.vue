<template>
  <v-container>
    <v-layout row>
    <v-flex xs12 sm6 offset-sm3>
      <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
      <v-card v-if="!loading">
          <v-layout column class="media">
            <v-card-title>
              <v-btn icon @click="$router.go(-1)">
                <v-icon>chevron_left</v-icon>
              </v-btn>
              <v-spacer></v-spacer>
              <v-btn icon class="mr-3" v-if="$store.state.user && $store.state.user.actor.id === actor.id">
                <v-icon>edit</v-icon>
              </v-btn>
              <v-btn icon>
                <v-icon>more_vert</v-icon>
              </v-btn>
            </v-card-title>
            <v-spacer></v-spacer>
            <div class="text-xs-center">
              <v-avatar size="125px">
                <img v-if="!account.avatar_url"
                  class="img-circle elevation-7 mb-1"
                  src="http://lorempixel.com/125/125/"
                >
                <img v-else
                     class="img-circle elevation-7 mb-1"
                     :src="account.avatar_url"
                >
              </v-avatar>
            </div>
            <v-container fluid grid-list-lg>
              <v-layout row>
                <v-flex xs7>
                  <div class="headline">{{ actor.display_name }}</div>
                  <div><span class="subheading">@{{ actor.username }}<span v-if="actor.domain">@{{ actor.domain }}</span></span></div>
                  <v-card-text v-if="actor.description" v-html="actor.description"></v-card-text>
                </v-flex>
              </v-layout>
            </v-container>
          </v-layout>
        <v-list three-line>
          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="indigo">phone</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <v-list-tile-title>(323) 555-6789</v-list-tile-title>
              <v-list-tile-sub-title>Work</v-list-tile-sub-title>
            </v-list-tile-content>
            <v-list-tile-action>
              <v-icon dark>chat</v-icon>
            </v-list-tile-action>
          </v-list-tile>
          <v-divider inset></v-divider>
          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="indigo">mail</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <v-list-tile-title>ali_connors@example.com</v-list-tile-title>
              <v-list-tile-sub-title>Work</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-divider inset></v-divider>
          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="indigo">location_on</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <v-list-tile-title>1400 Main Street</v-list-tile-title>
              <v-list-tile-sub-title>Orlando, FL 79938</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
        </v-list>
        <v-container fluid grid-list-md v-if="actor.participatingEvents && actor.participatingEvents.length > 0">
          <v-subheader>Participated at</v-subheader>
          <v-layout row wrap>
            <v-flex v-for="event in actor.participatingEvents" :key="event.id">
              <v-card>
                <v-card-media
                  class="black--text"
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
                <v-card-title>
                  <div>
                    <span class="grey--text">{{ event.startDate | formatDate }} à {{ event.location }}</span><br>
                    <p>{{ event.description }}</p>
                    <p v-if="event.organizer">Organisé par <router-link :to="{name: 'Account', params: {'id': event.organizer.id}}">{{ event.organizer.username }}</router-link></p>
                  </div>
                </v-card-title>
                <v-card-actions>
                  <v-spacer></v-spacer>
                  <v-btn icon>
                    <v-icon>favorite</v-icon>
                  </v-btn>
                  <v-btn icon>
                    <v-icon>bookmark</v-icon>
                  </v-btn>
                  <v-btn icon>
                    <v-icon>share</v-icon>
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-flex>
          </v-layout>
        </v-container>
        <v-container fluid grid-list-md v-if="actor.organizingEvents && actor.organizingEvents.length > 0">
          <v-subheader>Organized events</v-subheader>
          <v-layout row wrap>
            <v-flex v-for="event in actor.organizingEvents" :key="event.id">
              <v-card>
                <v-card-media
                  class="black--text"
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
                <v-card-title>
                  <div>
                    <span class="grey--text">{{ event.startDate | formatDate }} à {{ event.location }}</span><br>
                    <p>{{ event.description }}</p>
                    <p v-if="event.organizer">Organisé par <router-link :to="{name: 'Account', params: {'id': event.organizer.id}}">{{ event.organizer.username }}</router-link></p>
                  </div>
                </v-card-title>
                <v-card-actions>
                  <v-spacer></v-spacer>
                  <v-btn icon>
                    <v-icon>favorite</v-icon>
                  </v-btn>
                  <v-btn icon>
                    <v-icon>bookmark</v-icon>
                  </v-btn>
                  <v-btn icon>
                    <v-icon>share</v-icon>
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-flex>
          </v-layout>
        </v-container>
      </v-card>
    </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
  import eventFetch from '@/api/eventFetch';

export default {
  name: 'Account',
  data() {
    return {
        actor: null,
        loading: true,
    }
  },
  props: {
      name: {
          type: String,
          required: true,
      }
  },
  created() {
    this.fetchData();
  },
  watch: {
    // call again the method if the route changes
    '$route': 'fetchData'
  },
  methods: {
    fetchData() {
      eventFetch(`/actors/${this.name}`, this.$store)
        .then(response => response.json())
        .then((response) => {
          this.actor = response.data;
          this.loading = false;
          console.log(this.actor);
        })
    }
  }
}
</script>
