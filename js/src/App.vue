<template>
  <div id="mobilizon">
    <NavBar />
    <div class="container">
      <b-message type="is-danger" :title="$t('Warning').toLocaleUpperCase()" closable aria-close-label="Close">
        <p>{{ $t('This is a demonstration site to test the beta version of Mobilizon.') }}</p>
        <p v-html="$t('<b>Please do not use it in any real way</b>: everything you create here (accounts, events, identities, etc.) will be automatically deleted every 48 hours.')" />
        <p>
          <span v-html="$t('Mobilizon is under development, we will add new features to this site during regular updates, until the release of <b>version 1 of the software in the first half of 2020</b>.')" />
          <i18n path="In the meantime, please consider that the software is not (yet) finished. More information {onBlog}.">
            <a slot="onBlog" href='https://framablog.org/?p=18299'>{{ $t('on our blog') }}</a>
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
import NavBar from '@/components/NavBar.vue';
import { Component, Vue } from 'vue-property-decorator';
import {
  AUTH_ACCESS_TOKEN,
  AUTH_USER_EMAIL,
  AUTH_USER_ID,
  AUTH_USER_ROLE,
} from '@/constants';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import Footer from '@/components/Footer.vue';
import Logo from '@/components/Logo.vue';
import { initializeCurrentActor } from '@/utils/auth';
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

/* Icons */
$mdi-font-path: "~@mdi/font/fonts";
@import "~@mdi/font/scss/materialdesignicons";

.fade-enter-active, .fade-leave-active {
  transition: opacity .5s;
}
.fade-enter, .fade-leave-to {
  opacity: 0;
}

  body {
    // background: #f7f8fa;
    background: #ebebeb;
  }

  #mobilizon > .container > .message .message-header {
    button.delete {
      background: #4a4a4a;
    }

    color: #111;
  }
</style>
