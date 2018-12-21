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
      <router-link :to="{ name: 'Home' }" class="hidden-sm-and-down white--text">Mobilizon
      </router-link>
    </v-toolbar-title>
    <v-autocomplete
      :loading="$apollo.loading"
      flat
      solo-inverted
      prepend-icon="search"
      :label="$gettext('Search')"
      required
      item-text="label"
      class="hidden-sm-and-down"
      :items="items"
      :search-input.sync="searchText"
      @keyup.enter="enter"
      v-model="model"
      return-object
    >
      <template slot="item" slot-scope="data">
        <!-- <div>{{ data }}</div> -->
        <v-list-tile v-if="data.item.__typename === 'Event'">
          <v-list-tile-avatar>
            <v-icon>event</v-icon>
          </v-list-tile-avatar>
          <v-list-tile-content v-text="data.item.label"></v-list-tile-content>
        </v-list-tile>
        <v-list-tile v-else-if="data.item.__typename === 'Actor'">
          <v-list-tile-avatar>
            <img :src="data.item.avatarUrl" v-if="data.item.avatarUrl">
            <v-icon v-else>account_circle</v-icon>
          </v-list-tile-avatar>
          <v-list-tile-content>
            <v-list-tile-title v-html="username_with_domain(data.item)"></v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
      </template>
    </v-autocomplete>
    <v-spacer></v-spacer>
    <v-menu
      offset-y
      :close-on-content-click="false"
      :nudge-width="200"
      v-model="notificationMenu"
      v-if="user"
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
          <v-btn flat @click="notificationMenu = false">
            <translate>Close</translate>
          </v-btn>
          <v-btn color="primary" flat @click="notificationMenu = false">
            <translate>Save</translate>
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-menu>
    <v-btn v-if="!user" :to="{ name: 'Login' }">
      <translate>Login</translate>
    </v-btn>
  </v-toolbar>
</template>

<style>
  nav.v-toolbar .v-input__slot {
    margin-bottom: 0;
  }
</style>

<script lang="ts">
  import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
  import { AUTH_USER_ACTOR, AUTH_USER_ID } from '@/constants';
  import { SEARCH } from '@/graphql/search';

  @Component({
    apollo: {
      search: {
        query: SEARCH,
        variables() {
          return {
            searchText: this.searchText,
          };
        },
        skip() {
          return !this.searchText;
        },
      },
    }
  })
  export default class NavBar extends Vue {
    @Prop({ required: true, type: Function }) toggleDrawer!: Function;

    notificationMenu = false;
    notifications = [
      { header: 'Coucou' },
      { title: 'T\'as une notification', subtitle: 'Et elle est cool' },
    ];
    model = null;
    search: any[] = [];
    searchText: string | null = null;
    searchSelect = null;
    actor: string | null = localStorage.getItem(AUTH_USER_ACTOR);
    user: string | null = localStorage.getItem(AUTH_USER_ID);

    get items() {
      return this.search.map(searchEntry => {
        switch (searchEntry.__typename) {
          case 'Actor':
            searchEntry.label = searchEntry.preferredUsername + (searchEntry.domain === null ? '' : `@${searchEntry.domain}`);
            break;
          case 'Event':
            searchEntry.label = searchEntry.title;
            break;
        }
        return searchEntry;
      });
    }

    @Watch('model')
    onModelChanged(val) {
      switch (val.__typename) {
        case 'Event':
          this.$router.push({ name: 'Event', params: { uuid: val.uuid } });
          break;
        case 'Actor':
          this.$router.push({ name: 'Account', params: { name: this.username_with_domain(val) } });
          break;
      }
    }

    username_with_domain(actor) {
      return actor.preferredUsername + (actor.domain === null ? '' : `@${actor.domain}`);
    }

    enter() {
      console.log('enter');
      this.$apollo.queries[ 'search' ].refetch();
    }

  }

</script>
