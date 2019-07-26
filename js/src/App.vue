<template>
  <div id="mobilizon">
    <NavBar />
    <main>
      <router-view />
    </main>
    <mobilizon-footer />
  </div>
</template>

<script lang="ts">
import NavBar from '@/components/NavBar.vue';
import { Component, Vue } from 'vue-property-decorator';
import { AUTH_TOKEN, AUTH_USER_ACTOR, AUTH_USER_EMAIL, AUTH_USER_ID } from '@/constants';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { ICurrentUser } from '@/types/current-user.model';
import Footer from '@/components/Footer.vue';
import Logo from '@/components/Logo.vue';

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
  currentUser!: ICurrentUser;

  actor = localStorage.getItem(AUTH_USER_ACTOR);

  async mounted () {
    await this.initializeCurrentUser();
  }

  getUser (): ICurrentUser|false {
    return this.currentUser.id ? this.currentUser : false;
  }

  private initializeCurrentUser() {
    const userId = localStorage.getItem(AUTH_USER_ID);
    const userEmail = localStorage.getItem(AUTH_USER_EMAIL);
    const token = localStorage.getItem(AUTH_TOKEN);

    if (userId && userEmail && token) {
      return this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: userId,
          email: userEmail,
          isLoggedIn: true,
        },
      });
    }
  }
}
</script>

<style lang="scss">
  @import "variables";

  /* Bulma imports */
  @import "~bulma/sass/base/_all.sass";
  @import "~bulma/sass/components/card.sass";
  @import "~bulma/sass/components/media.sass";
  @import "~bulma/sass/components/message.sass";
  @import "~bulma/sass/components/modal.sass";
  @import "~bulma/sass/components/navbar.sass";
  @import "~bulma/sass/components/pagination.sass";
  @import "~bulma/sass/components/dropdown.sass";
  @import "~bulma/sass/elements/box.sass";
  @import "~bulma/sass/elements/button.sass";
  @import "~bulma/sass/elements/container.sass";
  @import "~bulma/sass/form/_all";
  @import "~bulma/sass/elements/icon.sass";
  @import "~bulma/sass/elements/image.sass";
  @import "~bulma/sass/elements/other.sass";
  @import "~bulma/sass/elements/tag.sass";
  @import "~bulma/sass/elements/title.sass";
  @import "~bulma/sass/elements/notification";
  @import "~bulma/sass/grid/_all.sass";
  @import "~bulma/sass/layout/_all.sass";
  @import "~bulma/sass/utilities/_all";

  /* Buefy imports */
  @import "~buefy/src/scss/utils/_all";
  @import "~buefy/src/scss/components/datepicker";
  @import "~buefy/src/scss/components/notices";
  @import "~buefy/src/scss/components/dropdown";
  @import "~buefy/src/scss/components/autocomplete";
  @import "~buefy/src/scss/components/form";
  @import "~buefy/src/scss/components/modal";
  @import "~buefy/src/scss/components/tag";
  @import "~buefy/src/scss/components/taginput";
  @import "~buefy/src/scss/components/upload";

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
