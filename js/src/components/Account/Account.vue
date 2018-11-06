<template>
  <v-layout row>
  <v-flex xs12 sm6 offset-sm3>
    <ApolloQuery :query="FETCH_ACTOR" :variables="{ name }">
      <template slot-scope="{ result: { loading, error, data } }">
        <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
        <v-card v-if="data">
          <v-img :src="data.actor.banner || 'https://picsum.photos/400/'" height="300px">
            <v-layout column class="media">
              <v-card-title>
                <v-btn icon @click="$router.go(-1)">
                  <v-icon>chevron_left</v-icon>
                </v-btn>
                <v-spacer></v-spacer>
                <!-- <v-btn icon class="mr-3" v-if="actor.id === data.actor.id">
                  <v-icon>edit</v-icon>
                </v-btn> -->
                <v-menu bottom left>
                  <v-btn icon slot="activator">
                    <v-icon>more_vert</v-icon>
                  </v-btn>
                  <v-list>
                    <!-- <v-list-tile @click="logoutUser()" v-if="actor.id === data.actor.id">
                      <v-list-tile-title>User logout</v-list-tile-title>
                    </v-list-tile>
                    <v-list-tile @click="deleteAccount()" v-if="actor.id === data.actor.id">
                      <v-list-tile-title>Delete</v-list-tile-title>
                    </v-list-tile> -->
                  </v-list>
                </v-menu>
              </v-card-title>
              <v-spacer></v-spacer>
              <div class="text-xs-center">
                <v-avatar size="125px">
                  <img v-if="!data.actor.avatarUrl"
                    class="img-circle elevation-7 mb-1"
                    src="https://picsum.photos/125/125/"
                  >
                  <img v-else
                        class="img-circle elevation-7 mb-1"
                        :src="data.actor.avatarUrl"
                  >
                </v-avatar>
              </div>
              <v-container fluid grid-list-lg>
                <v-layout row>
                  <v-flex xs7>
                    <div class="headline">{{ data.actor.name }}</div>
                    <div><span class="subheading">@{{ data.actor.preferredUsername }}<span v-if="data.actor.domain">@{{ data.actor.domain }}</span></span></div>
                    <v-card-text v-if="data.actor.description" v-html="data.actor.description"></v-card-text>
                  </v-flex>
                </v-layout>
              </v-container>
            </v-layout>
          </v-img>
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
          <v-container fluid grid-list-md v-if="data.actor.participatingEvents && data.actor.participatingEvents.length > 0">
            <v-subheader>Participated at</v-subheader>
            <v-layout row wrap>
              <v-flex v-for="event in data.actor.participatingEvents" :key="event.id">
                <v-card>
                  <v-img
                    class="black--text"
                    height="200px"
                    src="https://picsum.photos/400/200/"
                  >
                    <v-container fill-height fluid>
                      <v-layout fill-height>
                        <v-flex xs12 align-end flexbox>
                          <span class="headline">{{ event.title }}</span>
                        </v-flex>
                      </v-layout>
                    </v-container>
                  </v-img>
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
          <v-container fluid grid-list-md v-if="data.actor.organizedEvents && data.actor.organizedEvents.length > 0">
            <v-subheader>Organized events</v-subheader>
            <v-layout row wrap>
              <v-flex v-for="event in data.actor.organizedEvents" :key="event.id" md6>
                <v-card>
                  <v-img
                    height="200px"
                    src="https://picsum.photos/400/200/"
                  />
                  <v-card-title primary-title>
                    <div>
                      <router-link :to="{name: 'Event', params: {uuid: event.uuid}}">
                        <div class="headline">{{ event.title }}</div>
                      </router-link>
                      <span class="grey--text" v-html="nl2br(event.description)"></span>
                    </div>
                  </v-card-title>
                  
                  <!-- <v-card-title>
                    <div>
                      <span class="grey--text" v-if="event.addressType === 'physical'">{{ event.startDate }} à {{ event.location }}</span><br>
                      <p v-if="event.organizer">Organisé par <router-link :to="{name: 'Account', params: {'id': event.organizer.id}}">{{ event.organizer.username }}</router-link></p>
                    </div>
                  </v-card-title> -->
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
      </template>
    </ApolloQuery>
  </v-flex>
  </v-layout>
</template>

<script>
import { FETCH_ACTOR } from '@/graphql/actor';

export default {
  name: 'Account',
  data() {
    return {
      loading: true,
    };
  },
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  created() {
  },
  watch: {
    // call again the method if the route changes
    $route: 'fetchData',
  },
  methods: {
    logoutUser() {
      // TODO : implement logout
      this.$router.push({ name: 'Home' });
    },
    nl2br: function(text) {
      return text.replace(/(?:\r\n|\r|\n)/g, '<br>');
    }
  },
};
</script>
