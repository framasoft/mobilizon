<template>
  <v-toolbar
    class="blue darken-3"
    dark
    app
    :clipped-left="$vuetify.breakpoint.lgAndUp"
    fixed
  >
    <v-toolbar-title style="width: 300px" class="ml-0 pl-3 white--text">
      <v-toolbar-side-icon @click.stop="toggleDrawer()"></v-toolbar-side-icon>
      <router-link :to="{ name: 'Home' }" class="hidden-sm-and-down white--text">Eventos
      </router-link>
    </v-toolbar-title>
    <v-autocomplete
      :loading="searchElement.loading"
      flat
      solo-inverted
      prepend-icon="search"
      label="Search"
      required
      item-text="displayedText"
      class="hidden-sm-and-down"
      :items="searchElement.items"
      :search-input.sync="search"
      v-model="searchSelect"
    >
      <template slot="item" slot-scope="data">
        <template v-if="typeof data.item !== 'object'">
          <v-list-tile-content v-text="data.item"></v-list-tile-content>
        </template>
        <template v-else>
          <v-list-tile-avatar>
            <img :src="data.item.avatar">
          </v-list-tile-avatar>
          <v-list-tile-content>
            <v-list-tile-title v-html="username_with_domain(data.item)"></v-list-tile-title>
            <v-list-tile-sub-title v-html="data.item.type"></v-list-tile-sub-title>
          </v-list-tile-content>
        </template>
      </template>
    </v-autocomplete>
    <v-spacer></v-spacer>
    <v-menu
      offset-y
      :close-on-content-click="false"
      :nudge-width="200"
      v-model="notificationMenu"
    >
      <v-btn icon slot="activator">
        <v-badge left color="red">
          <span slot="badge">{{ notifications.length }}</span>
          <v-icon>notifications</v-icon>
        </v-badge>
      </v-btn>
      <v-card>
        <v-list two-line>
          <template v-for="item in notifications">
            <v-subheader v-if="item.header" v-text="item.header" v-bind:key="item.header"></v-subheader>
            <v-divider v-else-if="item.divider" v-bind:inset="item.inset" v-bind:key="item.inset"></v-divider>
            <v-list-tile avatar v-else v-bind:key="item.title">
              <v-list-tile-content>
                <v-list-tile-title v-html="item.title"></v-list-tile-title>
                <v-list-tile-sub-title v-html="item.subtitle"></v-list-tile-sub-title>
              </v-list-tile-content>
            </v-list-tile>
          </template>
        </v-list>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn flat @click="notificationMenu = false">Close</v-btn>
          <v-btn color="primary" flat @click="notificationMenu = false">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-menu>
    <v-btn flat @click="$router.push({name: 'Account', params: { name: getUser().actor.username }})" v-if="$store.state.user">{{ this.displayed_name }}</v-btn>
  </v-toolbar>
</template>

<script>
  import eventFetch from '@/api/eventFetch';

  export default {
    name: 'NavBar',
    props: {
      toggleDrawer: {
        type: Function,
        required: true,
      },
    },
    data() {
      return {
        notificationMenu: false,
        notifications: [
          {header: 'Coucou'},
          {title: "T'as une notification", subtitle: 'Et elle est cool'},
        ],
        searchElement: {
          loading: false,
          items: [],
        },
        search: null,
        searchSelect: null,
      };
    },
    watch: {
      search (val) {
        val && this.querySelections(val)
      },
      searchSelect(val) {
        console.log(val);
        if (val.type === 'Event') {
          this.$router.push({name: 'Event', params: { name: val.organizer.username, slug: val.slug }});
        } else if (val.type === 'Locality') {
          this.$router.push({name: 'EventList', params: {location: val.geohash}});
        } else {
          this.$router.push({name: 'Account', params: { name : this.username_with_domain(val) }});
        }
      }
    },
    computed: {
      displayed_name: function() {
        return this.$store.state.user.actor.display_name === null ? this.$store.state.user.actor.username : this.$store.state.user.actor.display_name
      },
    },
    methods: {
      username_with_domain(actor) {
          if (actor.type !== 'Event') {
              return actor.username + (actor.domain === null ? '' : `@${actor.domain}`)
          }
          return actor.title;
      },
      getUser() {
        return this.$store.state.user === undefined ? false : this.$store.state.user;
      },
      querySelections(searchTerm) {
        this.searchElement.loading = true;
        eventFetch(`/search/${searchTerm}`, this.$store)
          .then(response => response.json())
          .then((results) => {
            console.log('results');
            console.log(results);
            const accountResults = results.data.actors.map((result) => {
              if (result.domain) {
                result.displayedText = `${result.username}@${result.domain}`;
              } else {
                result.displayedText = result.username;
              }
              return result;
            });

            const eventsResults = results.data.events.map((result) => {
                result.displayedText = result.title;
                return result;
            });
            // const cities = new Set();
            // const placeResults = results.places.map((result) => {
            //   result.displayedText = result.addressLocality;
            //   return result;
            // }).filter((result) => {
            //   if (cities.has(result.addressLocality)) {
            //     return false;
            //   }
            //   cities.add(result.addressLocality);
            //   return true;
            // });
            this.searchElement.items = accountResults.concat(eventsResults);
            this.searchElement.loading = false;
          });
      }
    }
  }
</script>

<style>
nav.v-toolbar .v-input__slot {
  margin-bottom: 0;
}
</style>