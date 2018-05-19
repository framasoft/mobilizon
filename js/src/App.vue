<template>
  <v-app id="libre-event">
    <v-navigation-drawer
      light
      clipped
      fixed
      app
      v-model="drawer"
      enable-resize-watcher
    >
      <v-list dense>
        <template v-for="(item, i) in items" v-if="showMenuItem(item.role)">
          <v-layout
            row
            v-if="item.heading"
            align-center
            :key="i"
          >
            <v-flex xs6>
              <v-subheader v-if="item.heading">
                {{ item.heading }}
              </v-subheader>
            </v-flex>
            <v-flex xs6 class="text-xs-center">
              <a href="#!" class="body-2 black--text">EDIT</a>
            </v-flex>
          </v-layout>
          <v-list-tile v-bind:key="item.route" v-else @click="$router.push({ name: item.route })">
            <v-list-tile-action>
              <v-icon>{{ item.icon }}</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <v-list-tile-title>
                {{ item.text }}
              </v-list-tile-title>
            </v-list-tile-content>
          </v-list-tile>
        </template>
      </v-list>
    </v-navigation-drawer>
    <NavBar></NavBar>
    <v-content>
      <v-container fluid fill-height>
        <v-layout xs-12>
          <transition>
            <router-view></router-view>
          </transition>
        </v-layout>
      </v-container>
    </v-content>
    <v-btn
      fixed
      dark
      fab
      bottom
      right
      color="pink"
      @click="$router.push({name: 'CreateEvent'})"
      v-if="getUser()"
    >
      <v-icon>add</v-icon>
    </v-btn>
    <v-footer class="indigo" app>
      <span class="white--text">© Thomas Citharel {{ new Date().getFullYear() }} - Made with Elixir, Phoenix & <a href="https://vuejs.org/">VueJS</a> & <a href="https://www.vuetifyjs.com/">Vuetify</a> with some love and some weeks</span>
    </v-footer>
    <v-snackbar
      :timeout="error.timeout"
      :error="true"
      v-model="error.show"
    >
      {{ error.text }}
      <v-btn dark flat @click.native="error.show = false">Close</v-btn>
    </v-snackbar>
  </v-app>
</template>

<script>

import NavBar from '@/components/NavBar';

export default {
  name: 'app',
  components: {
    NavBar,
  },
  data() {
    return {
      drawer: true,
      user: false,
      items: [
        { icon: 'poll', text: 'Events', route: 'EventList', role: null },
        { icon: 'group', text: 'Groups', route: 'GroupList', role: null },
        { icon: 'content_copy', text: 'Categories', route: 'CategoryList', role: 'ROLE_ADMIN' },
        { icon: 'settings', text: 'Settings', role: 'ROLE_USER' },
        { icon: 'chat_bubble', text: 'Send feedback', role: 'ROLE_USER' },
        { icon: 'help', text: 'Help', role: null },
        { icon: 'phonelink', text: 'App downloads', role: null },
      ],
      error: {
        timeout: 3000,
        show: false,
        text: '',
      },
      show_new_event_button: false,
    };
  },
  methods: {
    showMenuItem(elem) {
      return elem !== null && this.$store.state.user && this.$store.state.user.roles !== undefined ? this.$store.state.user.roles.includes(elem) : true;
    },
    getUser() {
      return this.$store.state.user === undefined ? false : this.$store.state.user;
    }
  },
};
</script>

<style>
</style>
