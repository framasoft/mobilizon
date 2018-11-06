<template>
  <v-container>
    <h1>Category List</h1>
    <v-container fluid grid-list-md class="grey lighten-4">
      <v-progress-circular v-if="$apollo.loading" indeterminate color="primary"></v-progress-circular>
      <v-layout row wrap v-else>
        <v-flex xs12 sm6 md3 v-for="category in categories" :key="category.id">
          <v-card>
            <v-img v-if="category.picture.url" :src="HTTP_ENDPOINT + category.picture.url" height="200px">
            </v-img>
            <v-card-title primary-title>
              <div>
                <h3 class="headline mb-0">{{ category.title }}</h3>
                <div>{{ category.description }}</div>
              </div>
            </v-card-title>
            <v-card-actions>
              <v-btn flat class="orange--text"><translate>Explore</translate></v-btn>
              <v-btn flat class="red--text" v-on:click="deleteCategory(category.id)"><translate>Delete</translate></v-btn>
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
import { FETCH_CATEGORIES } from '@/graphql/category';

// TODO : remove this hardcode


export default {
  name: 'Home',
  data() {
    return {
      categories: [],
      loading: true,
      HTTP_ENDPOINT: 'http://localhost:4000',
    };
  },
  apollo: {
    categories: {
      query: FETCH_CATEGORIES,
    },
  },
  methods: {
    deleteCategory(categoryId) {
      const router = this.$router;
      eventFetch(`/categories/${categoryId}`, this.$store, { method: 'DELETE' })
        .then(() => {
          this.categories = this.categories.filter(category => category.id !== categoryId);
          router.push('/category');
        });
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
