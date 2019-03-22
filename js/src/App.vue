<template>
  <div id="mobilizon">
    <NavBar></NavBar>
    <main class="container">
      <router-view></router-view>
    </main>
    <footer class="footer">
      <div class="content has-text-centered">
        <span
          v-translate="{
            date: new Date().getFullYear(),
            }"
        >© The Mobilizon Contributors %{date} - Made with Elixir, Phoenix, VueJS & with some love and some weeks</span>
      </div>
    </footer>
  </div>
</template>

<script lang="ts">
import NavBar from '@/components/NavBar.vue';
import { Component, Vue } from 'vue-property-decorator';
import { AUTH_TOKEN, AUTH_USER_ACTOR, AUTH_USER_EMAIL, AUTH_USER_ID } from '@/constants';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { ICurrentUser } from '@/types/current-user.model';

@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
  },
  components: {
    NavBar,
  },
})
export default class App extends Vue {
  drawer = false;
  fab = false;
  items = [
    {
      icon: 'poll',
      text: 'Events',
      route: 'EventList',
      role: null,
    },
    {
      icon: 'group',
      text: 'Groups',
      route: 'GroupList',
      role: null,
    },
    { icon: 'settings', text: 'Settings', role: 'ROLE_USER' },
    { icon: 'chat_bubble', text: 'Send feedback', role: 'ROLE_USER' },
    { icon: 'help', text: 'Help', role: null },
    { icon: 'phonelink', text: 'App downloads', role: null },
  ];
  error = {
    timeout: 3000,
    show: false,
    text: '',
  };
  currentUser!: ICurrentUser;

  actor = localStorage.getItem(AUTH_USER_ACTOR);

  mounted () {
    this.initializeCurrentUser();
  }

  get displayed_name () {
    // FIXME: load actor
    return 'no implemented';
    // return this.actor.display_name === null ? this.actor.username : this.actor.display_name
  }

  showMenuItem(elem) {
    // FIXME: load actor
    return false;
    // return elem !== null && this.user && this.user.roles !== undefined ? this.user.roles.includes(elem) : true
  }

  getUser (): ICurrentUser|false {
    return this.currentUser.id ? this.currentUser : false;
  }

  toggleDrawer() {
    this.drawer = !this.drawer;
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
        },
      });
    }
  }
}
</script>

<style>
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
</style>
