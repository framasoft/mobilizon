<template>
  <v-layout row>
  <v-flex xs12 sm6 offset-sm3>
    <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
    <v-card v-if="!loading">
      <v-toolbar dark color="primary">
        <v-toolbar-title>Identities</v-toolbar-title>
      </v-toolbar>
        <v-card-text>
          <v-list two-line>
            <v-list-tile
              v-for="actor in actors"
              :key="actor.id"
              avatar
              @click="$router.push({ name: 'Account', params: { name: actor.username } })"
            >
              <v-list-tile-action>
                <v-icon v-if="$store.state.defaultActor === actor.username" color="pink">star</v-icon>
              </v-list-tile-action>

              <v-list-tile-content>
                <v-list-tile-title v-text="actor.username"></v-list-tile-title>
                <v-list-tile-sub-title v-if="actor.display_name" v-text="actor.display_name"></v-list-tile-sub-title>
              </v-list-tile-content>

              <v-list-tile-avatar>
                <img :src="actor.avatar">
              </v-list-tile-avatar>
            </v-list-tile>
          </v-list>
          <v-divider v-if="showForm"></v-divider>
          <v-form v-if="showForm">
            <v-text-field
                label="Username"
                required
                type="text"
                v-model="newActor.preferred_username"
                :rules="[rules.required]"
                :error="this.state.username.status"
                :error-messages="this.state.username.msg"
                :suffix="this.host()"
                hint="You will be able to create more identities once registered"
                persistent-hint
            >
            </v-text-field>
            <v-textarea
                name="input-7-1"
                label="Profile description"
                hint="Will be displayed publicly on your profile"
            ></v-textarea>
          </v-form>
          <v-btn
            color="pink"
            dark
            absolute
            bottom
            right
            fab
            @click="toggleForm()"
            >
            <v-icon>{{ showForm ? 'check' : 'add' }}</v-icon>
          </v-btn>
        </v-card-text>
    </v-card>
  </v-flex>
  </v-layout>
</template>

<script>
import eventFetch from "@/api/eventFetch";
import auth from "@/auth";

export default {
  name: "Identities",
  data() {
    return {
      actors: [],
      newActor: {
        preferred_username: "",
        summary: ""
      },
      loading: true,
      showForm: false,
      rules: {
        required: value => !!value || "Required."
      },
      state: {
        username: {
          status: false,
          msg: []
        }
      }
    };
  },
  created() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      eventFetch(`/user`, this.$store)
        .then(response => response.json())
        .then(response => {
          this.actors = response.data.actors;
          this.loading = false;
        });
    },
    sendData() {
      this.loading = true;
      this.showForm = false;
      eventFetch(`/actors`, this.$store, {
        method: "POST",
        body: JSON.stringify({ actor: this.newActor })
      })
        .then(response => response.json())
        .then(response => {
          this.actors.push(response.data);
          this.loading = false;
        });
    },
    toggleForm() {
      if (this.showForm === true) {
        this.sendData();
      } else {
        this.showForm = true;
      }
    },
    host() {
      return `@${window.location.host}`;
    }
  }
};
</script>
