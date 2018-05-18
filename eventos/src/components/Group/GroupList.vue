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
            src="http://lorempixel.com/400/200/"
          >
            <v-container fill-height fluid>
              <v-layout fill-height>
                <v-flex xs12 align-end flexbox>
                  <span class="headline">{{ group.title }}</span>
                </v-flex>
              </v-layout>
            </v-container>
          </v-card-media>
          <v-card-title>
            <div>
              <span class="grey--text">{{ group.startDate | formatDate }} à {{ group.location }}</span><br>
              <p>{{ group.description }}</p>
              <p v-if="group.organizer">Organisé par <router-link :to="{name: 'Account', params: {'id': group.organizer.id}}">{{ group.organizer.username }}</router-link></p>
            </div>
          </v-card-title>
          <v-card-actions>
            <v-btn flat color="green" @click="joinGroup(group.id)"><v-icon v-if="group.locked">lock</v-icon>Join</v-btn>
            <v-btn flat color="orange" @click="viewEvent(group.id)">Explore</v-btn>
            <v-btn flat color="red" @click="deleteEvent(group.id)">Delete</v-btn>
          </v-card-actions>
        </v-card>
      </v-flex>
    </v-layout>
    <router-link :to="{ name: 'CreateGroup' }" class="btn btn-default">Create</router-link>
  </v-container>
</template>

<script>
  import eventFetch from '@/api/eventFetch';

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
      fetchData() {
        eventFetch('/groups', this.$store)
          .then(response => response.json())
          .then((data) => {
            this.loading = false;
            this.groups = data.data;
          });
      },
      deleteEvent(id) {
        const router = this.$router;
        eventFetch('/groups/' + id, this.$store, {'method': 'DELETE'})
          .then(response => response.json())
          .then(() => router.push('/groups'));
      },
      viewEvent(id) {
        this.$router.push({ name: 'Group', params: { id } })
      },
      joinGroup(id) {
        const router = this.$router;
        eventFetch('/groups/' + id + '/join', this.$store)
          .then(response => response.json())
          .then(() => router.push('/group/' + id))
      }
    },
  };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
