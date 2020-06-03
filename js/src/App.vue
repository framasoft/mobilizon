<template>
  <div id="mobilizon">
    <NavBar />
    <div class="container" v-if="config && config.demoMode">
      <b-message
        type="is-danger"
        :title="$t('Warning').toLocaleUpperCase()"
        closable
        aria-close-label="Close"
      >
        <p
          v-html="
            `${$t('This is a demonstration site to test the beta version of Mobilizon.')} ${$t(
              '<b>Please do not use it in any real way.</b>'
            )}`
          "
        />
        <p>
          <span
            v-html="
              $t(
                'Mobilizon is under development, we will add new features to this site during regular updates, until the release of <b>version 1 of the software in the first half of 2020</b>.'
              )
            "
          />
          <i18n
            path="In the meantime, please consider that the software is not (yet) finished. More information {onBlog}."
          >
            <a
              slot="onBlog"
              :href="
                $i18n.locale === 'fr'
                  ? 'https://framablog.org/?p=18268'
                  : 'https://framablog.org/?p=18299'
              "
              >{{ $t("on our blog") }}</a
            >
          </i18n>
        </p>
      </b-message>
    </div>
    <main>
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
import { AUTH_ACCESS_TOKEN, AUTH_USER_EMAIL, AUTH_USER_ID, AUTH_USER_ROLE } from "./constants";
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from "./graphql/user";
import Footer from "./components/Footer.vue";
import Logo from "./components/Logo.vue";
import { initializeCurrentActor } from "./utils/auth";
import { CONFIG } from "./graphql/config";
import { IConfig } from "./types/config.model";
@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    config: CONFIG,
  },
  components: {
    Logo,
    NavBar,
    "mobilizon-footer": Footer,
  },
})
export default class App extends Vue {
  config!: IConfig;

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

/* Bulma imports */
@import "~bulma/bulma";
@import "~bulma-divider";

/* Buefy imports */
@import "~buefy/src/scss/buefy";

/* Icons */
$mdi-font-path: "~@mdi/font/fonts";
@import "~@mdi/font/scss/materialdesignicons";

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter,
.fade-leave-to {
  opacity: 0;
}

body {
  // background: #f7f8fa;
  background: $body-background-color;
  font-family: BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Fira Sans",
    "Droid Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;

  /*main {*/
  /*  margin: 1rem auto 0;*/
  /*}*/
}

#mobilizon > .container > .message {
  margin: 1rem auto auto;
  .message-header {
    button.delete {
      background: #4a4a4a;
    }

    color: #111;
  }
}
</style>
