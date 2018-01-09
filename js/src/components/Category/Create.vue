<template>
  <div>
    <h3>Create a new category</h3>
    <v-form>
      <v-text-field
        label="Name of the category"
        v-model="category.name"
        :counter="100"
        required
      ></v-text-field>
      <input type="file" @change="processFile($event.target)">
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
          name: '',
          imageDataUri: null,
        },
      };
    },
    methods: {
      create() {
        const router = this.$router;
        eventFetch('/categories', this.$store, { method: 'POST', body: JSON.stringify(this.category) })
          .then(response => response.json())
          .then(() => {
            this.loading = false;
            router.push('/category')
          });
      },
      processFile(target) {
        const reader = new FileReader();
        const file = target.files[0];
        reader.addEventListener('load', () => {
          this.category.imageDataUri = reader.result;
        });

        if (file) {
          reader.readAsDataURL(file);
        }
      }
    },
  };
</script>

<style>
  .markdown-render h1 {
    font-size: 2em;
  }
</style>
