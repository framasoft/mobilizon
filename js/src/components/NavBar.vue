<template>
  <b-navbar type="is-secondary" shadow wrapper-class="container">
    <template slot="brand">
      <b-navbar-item tag="router-link" :to="{ name: RouteName.HOME }"><logo /></b-navbar-item>
    </template>
    <template slot="start">
      <b-navbar-item tag="router-link" :to="{ name: RouteName.EXPLORE }">{{ $t('Explore') }}</b-navbar-item>
      <b-navbar-item tag="router-link" :to="{ name: RouteName.MY_EVENTS }">{{ $t('Events') }}</b-navbar-item>
      <b-navbar-item tag="span">
        <b-button tag="router-link" :to="{ name: RouteName.CREATE_EVENT }" type="is-success">{{ $t('Create') }}</b-button>
      </b-navbar-item>
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

        <b-navbar-item tag="span" v-for="identity in identities" v-if="identities.length > 0" :active="identity.id === currentActor.id" :key="identity.id">
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


          <b-navbar-item tag="router-link" :to="{ name: RouteName.UPDATE_IDENTITY }">
            {{ $t('My account') }}
          </b-navbar-item>

<!--          <b-navbar-item tag="router-link" :to="{ name: RouteName.CREATE_GROUP }">-->
<!--            {{ $t('Create group') }}-->
<!--          </b-navbar-item>-->

          <b-navbar-item v-if="currentUser.role === ICurrentUserRole.ADMINISTRATOR" tag="router-link" :to="{ name: RouteName.DASHBOARD }">
            {{ $t('Administration') }}
          </b-navbar-item>

          <b-navbar-item tag="span">
            <span @click="logout">{{ $t('Log out') }}</span>
          </b-navbar-item>
      </b-navbar-dropdown>

      <b-navbar-item v-else tag="div">
        <div class="buttons">
          <router-link class="button is-primary" v-if="config && config.registrationsOpen" :to="{ name: RouteName.REGISTER }">
            <strong>{{ $t('Sign up') }}</strong>
          </router-link>

          <router-link class="button is-light" :to="{ name: RouteName.LOGIN }">{{ $t('Log in') }}</router-link>
        </div>
      </b-navbar-item>
    </template>
  </b-navbar>
</template>

<script lang="ts">
import { Component, Vue, Watch } from 'vue-property-decorator';
import { CURRENT_USER_CLIENT } from '@/graphql/user';
import { changeIdentity, logout } from '@/utils/auth';
import { CURRENT_ACTOR_CLIENT, IDENTITIES } from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { ICurrentUser, ICurrentUserRole } from '@/types/current-user.model';
import Logo from '@/components/Logo.vue';
import SearchField from '@/components/SearchField.vue';
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
  currentActor!: IPerson;
  config!: IConfig;
  currentUser!: ICurrentUser;
  ICurrentUserRole = ICurrentUserRole;
  identities: IPerson[] = [];
  RouteName = RouteName;

  @Watch('currentActor')
  async initializeListOfIdentities() {
    const { data } = await this.$apollo.query<{ identities: IPerson[] }>({
      query: IDENTITIES,
    });
    if (data) {
      this.identities = data.identities.map(identity => new Person(identity));

      // If we don't have any identities, the user has validated their account,
      // is logging for the first time but didn't create an identity somehow
      if (this.identities.length === 0) {
        await this.$router.push({
          name: RouteName.REGISTER_PROFILE,
          params: { email: this.currentUser.email, userAlreadyActivated: 'true' },
        });
      }
    }
  }

  async logout() {
    await logout(this.$apollo.provider.defaultClient);
    this.$buefy.notification.open({
      message: this.$t('You have been disconnected') as string,
      type: 'is-success',
      position: 'is-bottom-right',
      duration: 5000,
    });

    if (this.$route.name === RouteName.HOME) return;
    await this.$router.push({ name: RouteName.HOME });
  }

  async setIdentity(identity: IPerson) {
    return await changeIdentity(this.$apollo.provider.defaultClient, identity);
  }
}
</script>
<style lang="scss" scoped>
@import "../variables.scss";

nav {
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

    &:hover {
      background: whitesmoke;
    }
  }

  .navbar-item.has-dropdown a.navbar-link figure {
    margin-right: 0.75rem;
  }
}
</style>
