<template>
  <v-toolbar
    class="blue darken-3"
    dark
    app
    clipped-left
    fixed
  >
    <v-toolbar-title style="width: 300px" class="ml-0 pl-3">
      <v-toolbar-side-icon @click.stop="drawer = !drawer"></v-toolbar-side-icon>
      <router-link :to="{ name: 'Home' }">
        Libre-Event
      </router-link>
    </v-toolbar-title>
    <v-select
      autocomplete
      :loading="searchElement.loading"
      light
      solo
      prepend-icon="search"
      placeholder="Search"
      required
      item-text="displayedText"
      :items="searchElement.items"
      :search-input.sync="search"
      v-model="searchSelect"
    ></v-select>
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
    <v-btn flat @click="$router.push({name: 'Account', params: {'id': getUser().account.id}})" v-if="$store.state.user">{{ this.displayed_name }}</v-btn>
  </v-toolbar>
</template>

<script>
  import eventFetch from '@/api/eventFetch';

  export default {
    name: 'NavBar',
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
        if (val.hasOwnProperty('addressLocality')) {
          this.$router.push({name: 'EventList', params: {location: val.geohash}});
        } else {
          this.$router.push({name: 'Account', params: {id: val.id}});
        }
      }
    },
    computed: {
      displayed_name: function() {
        return this.$store.state.user.account.display_name === null ? this.$store.state.user.account.username : this.$store.state.user.account.display_name
      },
    },
    methods: {
      getUser() {
        return this.$store.state.user === undefined ? false : this.$store.state.user;
      },
      querySelections(searchTerm) {
        this.searchElement.loading = true;
        eventFetch('/find/', this.$store, {method: 'POST', body: JSON.stringify({search: searchTerm})})
          .then(response => response.json())
          .then((results) => {
            console.log(results);
            const accountResults = results.accounts.map((result) => {
              if (result.server) {
                result.displayedText = `${result.username}@${result.server.address}`;
              } else {
                result.displayedText = result.username;
              }
              return result;
            });
            const cities = new Set();
            const placeResults = results.places.map((result) => {
              result.displayedText = result.addressLocality;
              return result;
            }).filter((result) => {
              if (cities.has(result.addressLocality)) {
                return false;
              }
              cities.add(result.addressLocality);
              return true;
            });
            this.searchElement.items = accountResults.concat(placeResults);
            this.searchElement.loading = false;
          });
      }
    }
  }
</script>
