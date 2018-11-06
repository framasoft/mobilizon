<template>
  <v-container>
    <h1>Group List</h1>

    <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
    <v-layout row wrap justify-space-around>
      <v-flex xs12 md3 v-for="group in groups" :key="group.id">
        <v-card>
          <v-card-media
            class="black--text"
            height="200px"
            src="https://picsum.photos/400/200/"
          >
            <v-container fill-height fluid>
              <v-layout fill-height>
                <v-flex xs12 align-end flexbox>
                  <span class="headline">{{ group.username }}</span>
                </v-flex>
              </v-layout>
            </v-container>
          </v-card-media>
          <v-card-title>
            <div>
              <p>{{ group.summary }}</p>
              <p v-if="group.organizer">Organisé par <router-link :to="{name: 'Account', params: {'id': group.organizer.id}}">{{ group.organizer.username }}</router-link></p>
            </div>
          </v-card-title>
          <v-card-actions>
            <v-btn flat color="green" @click="joinGroup(group)"><v-icon v-if="group.locked">lock</v-icon>Join</v-btn>
            <v-btn flat color="orange" @click="viewActor(group)">Explore</v-btn>
            <v-btn flat color="red" @click="deleteGroup(group)">Delete</v-btn>
          </v-card-actions>
        </v-card>
      </v-flex>
    </v-layout>
    <router-link :to="{ name: 'CreateGroup' }" class="btn btn-default">Create</router-link>
  </v-container>
</template>

<script>
export default {
  name: 'GroupList',
  data() {
    return {
      groups: [],
      loading: true,
    };
  },
  created() {
    this.fetchData();
  },
  methods: {
    username_with_domain(actor) {
      return actor.username + (actor.domain === null ? '' : `@${actor.domain}`);
    },
    fetchData() {
      eventFetch('/groups', this.$store)
        .then(response => response.json())
        .then((data) => {
          console.log(data);
          this.loading = false;
          this.groups = data.data;
        });
    },
    deleteGroup(group) {
      const router = this.$router;
      eventFetch(`/groups/${this.username_with_domain(group)}`, this.$store, { method: 'DELETE' })
        .then(response => response.json())
        .then(() => router.push('/groups'));
    },
    viewActor(actor) {
      this.$router.push({ name: 'Group', params: { name: this.username_with_domain(actor) } });
    },
    joinGroup(group) {
      const router = this.$router;
      eventFetch(`/groups/${this.username_with_domain(group)}/join`, this.$store, { method: 'POST' })
        .then(response => response.json())
        .then(() => router.push({ name: 'Group', params: { name: this.username_with_domain(group) } }));
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
