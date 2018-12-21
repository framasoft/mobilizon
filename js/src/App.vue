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
        <v-list-group
          value="false"
        >
          <v-list-tile avatar v-if="actor" slot="activator">
            <v-list-tile-avatar>
              <img v-if="!actor.avatar"
                   class="img-circle elevation-7 mb-1"
                   src="https://picsum.photos/125/125/"
              >
              <img v-else
                   class="img-circle elevation-7 mb-1"
                   :src="actor.avatar"
              >
            </v-list-tile-avatar>

            <v-list-tile-content @click="$router.push({name: 'Account', params: { name: actor.username }})">
              <v-list-tile-title>{{ this.displayed_name }}</v-list-tile-title>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile avatar v-if="actor">
            <v-list-tile-avatar>
              <img
                class="img-circle elevation-7 mb-1"
                src="https://picsum.photos/125/125/"
              >
            </v-list-tile-avatar>

            <v-list-tile-content>
              <v-list-tile-title>Autre identité</v-list-tile-title>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile @click="$router.push({ name: 'Identities' })">
            <v-list-tile-action>
              <v-icon>group</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <v-list-tile-title>Identities</v-list-tile-title>
            </v-list-tile-content>
          </v-list-tile>
        </v-list-group>
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
    <NavBar v-bind="{toggleDrawer}"></NavBar>
    <v-content>
      <v-container fluid fill-height :class="{'px-0': $vuetify.breakpoint.xsOnly }">
        <v-layout xs12>
          <transition name="router">
            <router-view></router-view>
          </transition>
        </v-layout>
      </v-container>
    </v-content>
    <v-speed-dial
      v-model="fab"
      bottom
      right
      fixed
      direction="top"
      open-on-hover
      transition="scale-transition"
      v-if="user"
    >
      <v-btn
        slot="activator"
        v-model="fab"
        color="blue darken-2"
        dark
        fab
      >
        <v-icon>add</v-icon>
        <v-icon>close</v-icon>
      </v-btn>
      <v-btn
        fab
        dark
        small
        color="pink"
        @click="$router.push({name: 'CreateEvent'})"
      >
        <v-icon>event</v-icon>
      </v-btn>
      <v-btn
        fab
        dark
        small
        color="purple"
        @click="$router.push({name: 'CreateGroup'})"
      >
        <v-icon>group</v-icon>
      </v-btn>
    </v-speed-dial>
    <v-footer class="indigo" app>
      <span
        class="white--text"
        v-translate="{
          date: new Date().getFullYear(),
          }">© The Mobilizon Contributors %{date} - Made with Elixir, Phoenix & <a href="https://vuejs.org/">VueJS</a> & <a
        href="https://www.vuetifyjs.com/">Vuetify</a> with some love and some weeks
      </span>
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

<script lang="ts">
  import NavBar from '@/components/NavBar.vue';
  import { Component, Vue } from 'vue-property-decorator';
  import { AUTH_USER_ACTOR, AUTH_USER_ID } from '@/constants';

  @Component({
    components: {
      NavBar
    }
  })
  export default class App extends Vue {
    drawer = false
    fab = false
    user = localStorage.getItem(AUTH_USER_ID)
    items = [
      {
        icon: 'poll', text: 'Events', route: 'EventList', role: null
      },
      {
        icon: 'group', text: 'Groups', route: 'GroupList', role: null
      },
      {
        icon: 'content_copy', text: 'Categories', route: 'CategoryList', role: 'ROLE_ADMIN'
      },
      { icon: 'settings', text: 'Settings', role: 'ROLE_USER' },
      { icon: 'chat_bubble', text: 'Send feedback', role: 'ROLE_USER' },
      { icon: 'help', text: 'Help', role: null },
      { icon: 'phonelink', text: 'App downloads', role: null }
    ]
    error = {
      timeout: 3000,
      show: false,
      text: ''
    }

    show_new_event_button = false
    actor = localStorage.getItem(AUTH_USER_ACTOR)

    get displayed_name () {
      // FIXME: load actor
      return 'no implemented'
      // return this.actor.display_name === null ? this.actor.username : this.actor.display_name
    }

    showMenuItem (elem) {
      // FIXME: load actor
      return false
      // return elem !== null && this.user && this.user.roles !== undefined ? this.user.roles.includes(elem) : true
    }

    getUser () {
      return this.user === undefined ? false : this.user
    }

    toggleDrawer () {
      this.drawer = !this.drawer
    }
  }

</script>

<style>
  .router-enter-active, .router-leave-active {
    transition-property: opacity;
    transition-duration: .25s;
  }

  .router-enter-active {
    transition-delay: .25s;
  }

  .router-enter, .router-leave-active {
    opacity: 0
  }
</style>
