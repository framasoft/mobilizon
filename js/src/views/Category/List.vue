<template>
  <section>
    <h1 class="title">
      <translate>Category List</translate>
    </h1>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div class="columns">
      <div class="column card" v-for="category in categories" :key="category.id">
        <div class="card-image">
          <figure class="image is-4by3">
            <img v-if="category.picture.url" :src="HTTP_ENDPOINT + category.picture.url">
          </figure>
        </div>
        <div class="card-content">
          <h2 class="title is-4">{{ category.title }}</h2>
          <p>{{ category.description }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { FETCH_CATEGORIES } from "@/graphql/category";
import { Component, Vue } from "vue-property-decorator";

// TODO : remove this hardcode

@Component({
  apollo: {
    categories: {
      query: FETCH_CATEGORIES
    }
  }
})
export default class List extends Vue {
  categories = [];
  loading = true;
  HTTP_ENDPOINT = "http://localhost:4000";

  deleteCategory(categoryId) {
    const router = this.$router;
    // FIXME: remove eventFetch
    // eventFetch(`/categories/${categoryId}`, this.$store, { method: 'DELETE' })
    //   .then(() => {
    //     this.categories = this.categories.filter(category => category.id !== categoryId);
    //     router.push('/category');
    //   });
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
</style>
