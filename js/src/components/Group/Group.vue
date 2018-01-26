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
              <v-btn icon class="mr-3" v-if="$store.state.user">
                <v-icon>edit</v-icon>
              </v-btn>
              <v-btn icon>
                <v-icon>more_vert</v-icon>
              </v-btn>
            </v-card-title>
            <v-spacer></v-spacer>
            <div class="text-xs-center">
              <v-avatar size="125px">
                <img v-if="!group.avatar_url"
                     class="img-circle elevation-7 mb-1"
                     src="http://lorempixel.com/125/125/"
                >
                <img v-else
                     class="img-circle elevation-7 mb-1"
                     :src="group.avatar_url"
                >
              </v-avatar>
              <v-card-title class="pl-5 pt-5">
                <div class="display-1 pl-5 pt-5">{{ group.title }}<span v-if="group.server">@{{ group.server.address }}</span></div>
              </v-card-title>
              <v-card-text v-html="group.description"></v-card-text>
            </div>
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
            <v-list-tile v-if="group.address">
              <v-list-tile-action>
                <v-icon color="indigo">location_on</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>{{ group.address.streetAddress }}</v-list-tile-title>
                <v-list-tile-sub-title>{{ group.address.postalCode }} {{ group.address.locality }}</v-list-tile-sub-title>
              </v-list-tile-content>
            </v-list-tile>
          </v-list>
          <v-container fluid grid-list-md v-if="group.members.length > 0">
            <v-subheader>Membres</v-subheader>
            <v-layout row>
              <v-flex xs2 v-for="member in group.members" :key="member.id">
                <router-link :to="{name: 'Account', params: {'id': member.account.id}}">
                  <v-badge overlap>
                    <span slot="badge" v-if="member.role == 3"><v-icon>stars</v-icon></span>
                    <v-avatar size="75px">
                      <img v-if="!member.account.avatar_url"
                           class="img-circle elevation-7 mb-1"
                           src="http://lorempixel.com/125/125/"
                      >
                      <img v-else
                           class="img-circle elevation-7 mb-1"
                           :src="member.account.avatar_url"
                      >
                    </v-avatar>
                  </v-badge>
                </router-link>
                <span>{{ groupAccount.account.username }}</span>
              </v-flex>
            </v-layout>
          </v-container>
          <v-container fluid grid-list-md v-if="group.events.length > 0">
            <v-subheader>Participated at</v-subheader>
            <v-layout row wrap>
              <v-flex v-for="event in group.events" :key="event.id">
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
    name: 'Group',
    props: ['id'],
    data() {
      return {
        group: {
          id: this.id,
          title: '',
          description: '',
        },
        loading: true,
      }
    },
    methods: {
      fetchData() {
        eventFetch(`/groups/${this.id}`, this.$store)
          .then(response => response.json())
          .then((data) => {
            this.loading = false;
            this.group = data.data;
          });
      },
      deleteGroup() {
        const router = this.$router;
        eventFetch(`/groups/${this.id}`, this.$store, { method: 'DELETE' })
          .then(response => response.json())
          .then(() => router.push('/groups'));
      },
    },
    created() {
      this.fetchData();
    },
  }
</script>
