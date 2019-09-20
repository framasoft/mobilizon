<template>
  <b-navbar type="is-secondary" shadow wrapper-class="container">
    <template slot="brand">
      <b-navbar-item tag="router-link" :to="{ name: 'Home' }"><logo /></b-navbar-item>
    </template>
    <template slot="start">
      <b-navbar-item tag="router-link" :to="{ name: EventRouteName.MY_EVENTS }">{{ $t('Events') }}</b-navbar-item>
    </template>
    <template slot="end">
      <b-navbar-item tag="div">
        <search-field />
      </b-navbar-item>

      <b-navbar-dropdown v-if="currentUser.isLoggedIn" right>
        <template slot="label" v-if="currentActor" class="navbar-dropdown-profile">
          <figure class="image is-32x32" v-if="currentActor.avatar">
            <img class="is-rounded" alt="avatarUrl" :src="currentActor.avatar.url">
          </figure>
          <span>{{ currentActor.preferredUsername }}</span>
        </template>

        <b-navbar-item tag="span" v-for="identity in identities" v-if="identities.length > 0" :active="identity.id === currentActor.id">
          <span @click="setIdentity(identity)">
            <div class="media-left">
              <figure class="image is-32x32" v-if="identity.avatar">
                <img class="is-rounded" :src="identity.avatar.url" alt="" />
              </figure>
            </div>

            <div class="media-content">
              <span>{{ identity.displayName() }}</span>
            </div>
          </span>

          <hr class="navbar-divider">
        </b-navbar-item>


          <b-navbar-item>
            <router-link :to="{ name: 'UpdateIdentity' }">{{ $t('My account') }}</router-link>
          </b-navbar-item>

          <b-navbar-item>
            <router-link :to="{ name: ActorRouteName.CREATE_GROUP }">{{ $t('Create group') }}</router-link>
          </b-navbar-item>

          <b-navbar-item v-if="currentUser.role === ICurrentUserRole.ADMINISTRATOR">
            <router-link :to="{ name: AdminRouteName.DASHBOARD }">{{ $t('Administration') }}</router-link>
          </b-navbar-item>

          <b-navbar-item v-on:click="logout()">{{ $t('Log out') }}</b-navbar-item>
      </b-navbar-dropdown>

      <b-navbar-item v-else tag="div">
        <div class="buttons">
          <router-link class="button is-primary" v-if="config && config.registrationsOpen" :to="{ name: 'Register' }">
            <strong>{{ $t('Sign up') }}</strong>
          </router-link>

          <router-link class="button is-light" :to="{ name: 'Login' }">{{ $t('Log in') }}</router-link>
        </div>
      </b-navbar-item>
    </template>
  </b-navbar>
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
import {EventRouteName} from "@/router/event";

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
  EventRouteName = EventRouteName;

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
    console.log('setIdentity');
    return await changeIdentity(this.$apollo.provider.defaultClient, identity);
  }
}
</script>
<style lang="scss" scoped>
@import "../variables.scss";

nav {
  /*border-bottom: solid 1px #0a0a0a;*/

  .navbar-dropdown .navbar-item {
    cursor: pointer;

    span {
      display: inherit;
    }

    &.is-active {
      background: $secondary;
    }

    img {
      max-height: 2.5em;
    }
  }

  .navbar-item.has-dropdown a.navbar-link figure {
    margin-right: 0.75rem;
  }
}
</style>
