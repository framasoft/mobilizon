<template>
  <div id="mobilizon">
    <NavBar />
    <div v-if="config && config.demoMode">
      <b-message
        class="container"
        type="is-danger"
        :title="$t('Warning').toLocaleUpperCase()"
        closable
        aria-close-label="Close"
      >
        <p>
          {{ $t("This is a demonstration site to test Mobilizon.") }}
          <b>{{ $t("Please do not use it in any real way.") }}</b>
          {{
            $t(
              "This website isn't moderated and the data that you enter will be automatically destroyed every day at 00:01 (Paris timezone)."
            )
          }}
        </p>
      </b-message>
    </div>
    <error v-if="error" :error="error" />

    <main v-else>
      <transition name="fade" mode="out-in">
        <router-view />
      </transition>
    </main>
    <mobilizon-footer />
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import NavBar from "./components/NavBar.vue";
import {
  AUTH_ACCESS_TOKEN,
  AUTH_USER_EMAIL,
  AUTH_USER_ID,
  AUTH_USER_ROLE,
} from "./constants";
import {
  CURRENT_USER_CLIENT,
  UPDATE_CURRENT_USER_CLIENT,
} from "./graphql/user";
import Footer from "./components/Footer.vue";
import Logo from "./components/Logo.vue";
import { initializeCurrentActor } from "./utils/auth";
import { CONFIG } from "./graphql/config";
import { IConfig } from "./types/config.model";
import { ICurrentUser } from "./types/current-user.model";

@Component({
  apollo: {
    currentUser: CURRENT_USER_CLIENT,
    config: CONFIG,
  },
  components: {
    Logo,
    NavBar,
    error: () =>
      import(/* webpackChunkName: "editor" */ "./components/Error.vue"),
    "mobilizon-footer": Footer,
  },
})
export default class App extends Vue {
  config!: IConfig;

  currentUser!: ICurrentUser;

  error: Error | null = null;

  async created(): Promise<void> {
    if (await this.initializeCurrentUser()) {
      await initializeCurrentActor(this.$apollo.provider.defaultClient);
    }
  }

  errorCaptured(error: Error): void {
    this.error = error;
  }

  private async initializeCurrentUser() {
    const userId = localStorage.getItem(AUTH_USER_ID);
    const userEmail = localStorage.getItem(AUTH_USER_EMAIL);
    const accessToken = localStorage.getItem(AUTH_ACCESS_TOKEN);
    const role = localStorage.getItem(AUTH_USER_ROLE);

    if (userId && userEmail && accessToken && role) {
      return this.$apollo.mutate({
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

/* Icons */
$mdi-font-path: "~@mdi/font/fonts";
@import "~@mdi/font/scss/materialdesignicons";

@import "common";

#mobilizon {
  min-height: 100vh;
  display: flex;
  flex-direction: column;

  main {
    flex-grow: 1;
  }
}
</style>
