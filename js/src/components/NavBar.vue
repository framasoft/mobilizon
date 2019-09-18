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
              v-if="currentActor"
            >
              <figure class="image is-24x24" v-if="currentActor.avatar">
                <img alt="avatarUrl" :src="currentActor.avatar.url">
              </figure>
              <span>{{ currentActor.preferredUsername }}</span>
            </a>

            <div class="navbar-dropdown is-boxed">
              <div v-for="identity in identities" v-if="identities.length > 0">
                <a class="navbar-item" @click="setIdentity(identity)" :class="{ 'is-active': identity.id === currentActor.id }">
                   <div class="media-left">
                      <figure class="image is-24x24" v-if="identity.avatar">
                        <img class="is-rounded" :src="identity.avatar.url">
                      </figure>
                    </div>

                    <div class="media-content">
                      <h3>{{ identity.displayName() }}</h3>
                    </div>
                </a>

                <hr class="navbar-divider">
              </div>

              <a class="navbar-item">
                <router-link :to="{ name: 'UpdateIdentity' }">{{ $t('My account') }}</router-link>
              </a>

              <a class="navbar-item">
                <router-link :to="{ name: ActorRouteName.CREATE_GROUP }">{{ $t('Create group') }}</router-link>
              </a>

              <a class="navbar-item" v-if="currentUser.role === ICurrentUserRole.ADMINISTRATOR">
                <router-link :to="{ name: AdminRouteName.DASHBOARD }">{{ $t('Administration') }}</router-link>
              </a>

              <a class="navbar-item" v-on:click="logout()">{{ $t('Log out') }}</a>
            </div>
          </div>

          <div class="navbar-item" v-else>
            <div class="buttons">
              <router-link class="button is-primary" v-if="config && config.registrationsOpen" :to="{ name: 'Register' }">
                <strong>{{ $t('Sign up') }}</strong>
              </router-link>

              <router-link class="button is-primary" :to="{ name: 'Login' }">{{ $t('Log in') }}</router-link>
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
import { changeIdentity, logout } from '@/utils/auth';
import { CURRENT_ACTOR_CLIENT, IDENTITIES, UPDATE_CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { ICurrentUser, ICurrentUserRole } from '@/types/current-user.model';
import Logo from '@/components/Logo.vue';
import SearchField from '@/components/SearchField.vue';
import { ActorRouteName } from '@/router/actor';
import { AdminRouteName } from '@/router/admin';
import { RouteName } from '@/router';

@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    identities: {
      query: IDENTITIES,
      update: ({ identities }) => identities ? identities.map(identity => new Person(identity)) : [],
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
  currentActor!: IPerson;
  config!: IConfig;
  currentUser!: ICurrentUser;
  ICurrentUserRole = ICurrentUserRole;
  identities: IPerson[] = [];
  showNavbar: boolean = false;

  ActorRouteName = ActorRouteName;
  AdminRouteName = AdminRouteName;

  @Watch('currentActor')
  async initializeListOfIdentities() {
    const { data } = await this.$apollo.query<{ identities: IPerson[] }>({
      query: IDENTITIES,
    });
    if (data) {
      this.identities = data.identities.map(identity => new Person(identity));
    }
  }

  // @Watch('currentUser')
  // async onCurrentUserChanged() {
  //   // Refresh logged person object
  //   if (this.currentUser.isLoggedIn) {
  //     const result = await this.$apollo.query({
  //       query: CURRENT_ACTOR_CLIENT,
  //     });
  //     console.log(result);
  //
  //     this.loggedPerson = result.data.currentActor;
  //   } else {
  //     this.loggedPerson = null;
  //   }
  // }

  async logout() {
    await logout(this.$apollo.provider.defaultClient);

    if (this.$route.name === RouteName.HOME) return;
    return this.$router.push({ name: RouteName.HOME });
  }

  async setIdentity(identity: IPerson) {
    return await changeIdentity(this.$apollo.provider.defaultClient, identity);
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
