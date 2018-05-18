<template>
  <div>
    <h3>Create a new category</h3>
    <v-form>
      <v-text-field
        label="Name of the category"
        v-model="category.title"
        :counter="100"
        required
      ></v-text-field>
    </v-form>
    <v-btn color="primary" @click="create">Create category</v-btn>
  </div>
</template>

<script>
  import eventFetch from '@/api/eventFetch';

  export default {
    name: 'create-category',
    data() {
      return {
        category: {
          title: '',
        },
      };
    },
    methods: {
      create() {
        const router = this.$router;
        eventFetch('/categories', this.$store, { method: 'POST', body: JSON.stringify({ category: this.category }) })
          .then(response => response.json())
          .then(() => {
            this.loading = false;
            router.push('/category')
          });
      },
    },
  };
</script>

<style>
  .markdown-render h1 {
    font-size: 2em;
  }
</style>
