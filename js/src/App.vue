<template>
  <div id="mobilizon">
    <NavBar />
    <main class="container">
      <router-view />
    </main>
    <mobilizon-footer />
  </div>
</template>

<script lang="ts">
import NavBar from '@/components/NavBar.vue';
import { Component, Vue } from 'vue-property-decorator';
import {
  AUTH_ACCESS_TOKEN,
  AUTH_USER_ACTOR_ID,
  AUTH_USER_EMAIL,
  AUTH_USER_ID,
  AUTH_USER_ROLE,
} from '@/constants';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { ICurrentUser } from '@/types/current-user.model';
import Footer from '@/components/Footer.vue';
import Logo from '@/components/Logo.vue';
import { CURRENT_ACTOR_CLIENT, IDENTITIES, UPDATE_CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { IPerson } from '@/types/actor';
import { changeIdentity, initializeCurrentActor, saveActorData } from '@/utils/auth';

@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
  },
  components: {
    Logo,
    NavBar,
    'mobilizon-footer': Footer,
  },
})
export default class App extends Vue {
  async created() {
    if (await this.initializeCurrentUser()) {
      await initializeCurrentActor(this.$apollo.provider.defaultClient);
    }
  }

  private async initializeCurrentUser() {
    const userId = localStorage.getItem(AUTH_USER_ID);
    const userEmail = localStorage.getItem(AUTH_USER_EMAIL);
    const accessToken = localStorage.getItem(AUTH_ACCESS_TOKEN);
    const role = localStorage.getItem(AUTH_USER_ROLE);

    if (userId && userEmail && accessToken && role) {
      return await this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: userId,
          email: userEmail,
          isLoggedIn: true,
          role,
        },
      });
    }
    return false;
  }
}
</script>

<style lang="scss">
@import "variables";

/* Bulma imports */
@import "~bulma/bulma";

/* Buefy imports */
@import "~buefy/src/scss/buefy";

.router-enter-active,
.router-leave-active {
  transition-property: opacity;
  transition-duration: 0.25s;
}

.router-enter-active {
  transition-delay: 0.25s;
}

.router-enter,
.router-leave-active {
  opacity: 0;
}

  body {
    background: #f6f7f8;
  }
</style>
