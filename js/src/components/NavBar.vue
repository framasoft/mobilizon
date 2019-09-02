<template>
  <nav class="navbar is-fixed-top" role="navigation" aria-label="main navigation">
    <div class="container">
      <div class="navbar-brand">
        <router-link class="navbar-item" :to="{ name: 'Home' }"><logo /></router-link>

        <a
          role="button"
          class="navbar-burger burger"
          aria-label="menu"
          aria-expanded="false"
          data-target="navbarBasicExample"
          @click="showNavbar = !showNavbar" :class="{ 'is-active': showNavbar }"
        >
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>

      <div class="navbar-menu" :class="{ 'is-active': showNavbar }">
        <div class="navbar-end">
          <div class="navbar-item">
            <search-field />
          </div>

          <div class="navbar-item has-dropdown is-hoverable" v-if="currentUser.isLoggedIn">
            <a
              class="navbar-link"
              v-if="loggedPerson"
            >
              <figure class="image is-24x24" v-if="loggedPerson.avatar">
                <img alt="avatarUrl" :src="loggedPerson.avatar.url">
              </figure>
              <span>{{ loggedPerson.preferredUsername }}</span>
            </a>

            <div class="navbar-dropdown">
              <span class="navbar-item">
                <router-link :to="{ name: 'UpdateIdentity' }" v-translate>My account</router-link>
              </span>

              <span class="navbar-item">
                <router-link :to="{ name: ActorRouteName.CREATE_GROUP }" v-translate>Create group</router-link>
              </span>

              <a v-translate class="navbar-item" v-on:click="logout()">Log out</a>
            </div>
          </div>

          <div class="navbar-item" v-else>
            <div class="buttons">
              <router-link class="button is-primary" v-if="config && config.registrationsOpen" :to="{ name: 'Register' }">
                <strong v-translate>Sign up</strong>
              </router-link>

              <router-link class="button is-primary" :to="{ name: 'Login' }" v-translate>Log in</router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts">
import { Component, Vue, Watch } from 'vue-property-decorator';
import { CURRENT_USER_CLIENT } from '@/graphql/user';
import { logout } from '@/utils/auth';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IPerson } from '@/types/actor';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { ICurrentUser } from '@/types/current-user.model';
import Logo from '@/components/Logo.vue';
import SearchField from '@/components/SearchField.vue';
import { ActorRouteName } from '@/router/actor';

@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    config: {
      query: CONFIG,
    },
  },
  components: {
    Logo,
    SearchField,
  },
})
export default class NavBar extends Vue {
  notifications = [
    { header: 'Coucou' },
    { title: 'T\'as une notification', subtitle: 'Et elle est cool' },
  ];
  loggedPerson: IPerson | null = null;
  config!: IConfig;
  currentUser!: ICurrentUser;
  showNavbar: boolean = false;

  ActorRouteName = ActorRouteName;

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

  async logout() {
    await logout(this.$apollo.provider.defaultClient);

    return this.$router.push({ path: '/' });
  }
}
</script>
<style lang="scss" scoped>
@import "../variables.scss";

nav {
  border-bottom: solid 1px #0a0a0a;

  .navbar-item img {
    max-height: 2.5em;
  }
}
</style>
