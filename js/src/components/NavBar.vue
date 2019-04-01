<template>
  <nav class="navbar is-fixed-top" role="navigation" aria-label="main navigation">
    <div class="navbar-brand">
      <router-link class="navbar-item" :to="{ name: 'Home' }">Mobilizon</router-link>

      <a
        role="button"
        class="navbar-burger burger"
        aria-label="menu"
        aria-expanded="false"
        data-target="navbarBasicExample"
      >
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
      </a>
    </div>
    <div class="navbar-end">
      <div class="navbar-item">
        <div class="buttons">
          <router-link class="button is-primary" v-if="!currentUser.isLoggedIn && config && config.registrationsOpen" :to="{ name: 'Register' }">
            <strong>
              <translate>Sign up</translate>
            </strong>
          </router-link>
          <router-link class="button is-light" v-if="!currentUser.isLoggedIn" :to="{ name: 'Login' }">
            <translate>Log in</translate>
          </router-link>
          <router-link
            class="button is-light"
            v-if="currentUser.isLoggedIn && loggedPerson"
            :to="{ name: 'Profile', params: { name: loggedPerson.preferredUsername} }"
          >
            <figure class="image is-24x24">
              <img :src="loggedPerson.avatarUrl">
            </figure>
            <span>{{ loggedPerson.preferredUsername }}</span>
          </router-link>

          <span v-if="currentUser.isLoggedIn" class="button" v-on:click="logout()">Log out</span>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts">
import { Component, Vue, Watch } from 'vue-property-decorator';
import { SEARCH } from '@/graphql/search';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { onLogout } from '@/vue-apollo';
import { deleteUserData } from '@/utils/auth';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IActor, IPerson } from '@/types/actor.model';
import { RouteName } from '@/router';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { ICurrentUser } from '@/types/current-user.model'

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
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    config: {
      query: CONFIG,
    }
  }
})
export default class NavBar extends Vue {
  notifications = [
    { header: 'Coucou' },
    { title: "T'as une notification", subtitle: 'Et elle est cool' },
  ];
  model = null;
  search: any[] = [];
  searchText: string | null = null;
  searchSelect = null;
  loggedPerson: IPerson | null = null;
  config!: IConfig;
  currentUser!: ICurrentUser;

  get items() {
    return this.search.map(searchEntry => {
      switch (searchEntry.__typename) {
        case 'Actor':
          searchEntry.label =
            searchEntry.preferredUsername +
            (searchEntry.domain === null ? '' : `@${searchEntry.domain}`);
          break;
        case 'Event':
          searchEntry.label = searchEntry.title;
          break;
      }
      return searchEntry;
    });
  }

  @Watch('currentUser')
  async onCurrentUserChanged() {
    // Refresh logged person object
    if (this.currentUser.isLoggedIn) {
      const result = await this.$apollo.query({
        query: LOGGED_PERSON,
      });

      this.loggedPerson = result.data.loggedPerson;
    } else {
      this.loggedPerson = null;
    }
  }

  @Watch('model')
  onModelChanged(val) {
    switch (val.__typename) {
      case 'Event':
        this.$router.push({ name: RouteName.EVENT, params: { uuid: val.uuid } });
        break;

      case 'Actor':
        this.$router.push({
          name: RouteName.PROFILE,
          params: { name: this.usernameWithDomain(val) },
        });
        break;
    }
  }

  usernameWithDomain(actor: IActor) {
    return (
      actor.preferredUsername +
      (actor.domain === null ? '' : `@${actor.domain}`)
    );
  }

  enter() {
    console.log('enter');
    this.$apollo.queries['search'].refetch();
  }

  async logout() {
    await this.$apollo.mutate({
      mutation: UPDATE_CURRENT_USER_CLIENT,
      variables: {
        id: null,
        email: null,
        isLoggedIn: false,
      },
    });

    deleteUserData();

    onLogout(this.$apollo)

    return this.$router.push({ path: '/' })
  }
}
</script>
