<template>
  <v-container>
    <h1>Category List</h1>

    <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
    <v-container fluid grid-list-md class="grey lighten-4">
      <v-layout row wrap v-if="!loading">
        <v-flex xs12 sm6 md3 v-for="category in categories" :key="category.id">
          <v-card>
            <v-card-media v-if="category.image" :src="'/images/categories/' + category.image.name" height="200px">
            </v-card-media>
            <v-card-title primary-title>
              <div>
                <h3 class="headline mb-0">{{ category.title }}</h3>
                <div>{{ category.description }}</div>
              </div>
            </v-card-title>
            <v-card-actions>
              <v-btn flat class="orange--text">Explore</v-btn>
              <v-btn flat class="red--text" v-on:click="deleteCategory(category.id)">Delete</v-btn>
            </v-card-actions>
          </v-card>
        </v-flex>
        <v-layout v-if="categories.length <= 0">
          <h3>No categories :(</h3>
        </v-layout>
      </v-layout>
    </v-container>

    <router-link :to="{ name: 'CreateCategory' }" class="btn btn-default">Create</router-link>
  </v-container>
</template>

<script>
  import eventFetch from '@/api/eventFetch';

  export default {
    name: 'Home',
    data() {
      return {
        categories: [],
        loading: true,
      };
    },
    created() {
      this.fetchData();
    },
    methods: {
      fetchData() {
        eventFetch('/categories', this.$store)
          .then(response => response.json())
          .then((response) => {
            this.loading = false;
            this.categories = response.data;
          });
      },
      deleteCategory(categoryId) {
        const router = this.$router;
        eventFetch('/categories/' + categoryId, this.$store, {method: 'DELETE'})
          .then(() => {
          this.categories = this.categories.filter((category) => {
            return category.id !== categoryId;
          });
          router.push('/category');
        });
      }
    },
  };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
