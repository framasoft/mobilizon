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
          <router-link class="button is-primary" v-if="!currentUser.id" :to="{ name: 'Register' }">
            <strong>
              <translate>Sign up</translate>
            </strong>
          </router-link>
          <router-link class="button is-light" v-if="!currentUser.id" :to="{ name: 'Login' }">
            <translate>Log in</translate>
          </router-link>
          <router-link
            class="button is-light"
            v-if="currentUser.id && loggedPerson"
            :to="{ name: 'Profile', params: { name: loggedPerson.preferredUsername} }"
          >
            <figure class="image is-24x24">
              <img :src="loggedPerson.avatarUrl">
            </figure>
            <span>{{ loggedPerson.preferredUsername }}</span>
          </router-link>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { SEARCH } from "@/graphql/search";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { onLogout } from "@/vue-apollo";
import { deleteUserData } from "@/utils/auth";
import { LOGGED_PERSON } from "@/graphql/actor";
import { IActor, IPerson } from '@/types/actor.model';
import { RouteName } from '@/router'

@Component({
  apollo: {
    search: {
      query: SEARCH,
      variables() {
        return {
          searchText: this.searchText
        };
      },
      skip() {
        return !this.searchText;
      }
    },
    currentUser: {
      query: CURRENT_USER_CLIENT
    },
    loggedPerson: {
      query: LOGGED_PERSON
    }
  }
})
export default class NavBar extends Vue {
  notifications = [
    { header: "Coucou" },
    { title: "T'as une notification", subtitle: "Et elle est cool" }
  ];
  model = null;
  search: any[] = [];
  searchText: string | null = null;
  searchSelect = null;
  loggedPerson!: IPerson;

  get items() {
    return this.search.map(searchEntry => {
      switch (searchEntry.__typename) {
        case "Actor":
          searchEntry.label =
            searchEntry.preferredUsername +
            (searchEntry.domain === null ? "" : `@${searchEntry.domain}`);
          break;
        case "Event":
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
    console.log("enter");
    this.$apollo.queries["search"].refetch();
  }

  logout() {
    alert('logout !');

    deleteUserData();

    return onLogout(this.$apollo);
  }
}
</script>
