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
          <div class="navbar-item" v-if="!currentUser.isLoggedIn">
            <div class="buttons">
              <router-link class="button is-primary" v-if="config && config.registrationsOpen" :to="{ name: 'Register' }">
                <strong>
                  <translate>Sign up</translate>
                </strong>
              </router-link>
              <router-link class="button is-primary" :to="{ name: 'Login' }">
                <translate>Log in</translate>
              </router-link>
            </div>
          </div>
          <div class="navbar-item has-dropdown is-hoverable" v-else>
              <router-link
                class="navbar-link"
                v-if="currentUser.isLoggedIn && loggedPerson"
                :to="{ name: 'MyAccount' }"
              >
                <figure class="image is-24x24" v-if="loggedPerson.avatar">
                  <img :src="loggedPerson.avatar.url">
                </figure>
                <span>{{ loggedPerson.preferredUsername }}</span>
              </router-link>

            <div class="navbar-dropdown">
              <router-link :to="{ name: 'MyAccount' }" class="navbar-item">
                <translate>My account</translate>
              </router-link>

              <a class="navbar-item" v-on:click="logout()">
                <translate>Log out</translate>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts">
import { Component, Vue, Watch } from 'vue-property-decorator';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { onLogout } from '@/vue-apollo';
import { deleteUserData } from '@/utils/auth';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IPerson } from '@/types/actor';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { ICurrentUser } from '@/types/current-user.model';
import Logo from '@/components/Logo.vue';
import SearchField from '@/components/SearchField.vue';

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
    { title: "T'as une notification", subtitle: 'Et elle est cool' },
  ];
  loggedPerson: IPerson | null = null;
  config!: IConfig;
  currentUser!: ICurrentUser;
  showNavbar: boolean = false;

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
    await this.$apollo.mutate({
      mutation: UPDATE_CURRENT_USER_CLIENT,
      variables: {
        id: null,
        email: null,
        isLoggedIn: false,
      },
    });

    deleteUserData();

    onLogout(this.$apollo);

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
