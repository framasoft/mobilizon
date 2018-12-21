<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>
              <translate>Create a new category</translate>
            </v-toolbar-title>
          </v-toolbar>
          <v-card-text>
            <v-form>
              <v-text-field
                :label="$gettext('Name of the category')"
                v-model="title"
                :counter="100"
                required
              ></v-text-field>
              <v-textarea
                :label="$gettext('Description')"
                v-model="description"
              ></v-textarea>
              <v-flex xs12 class="text-xs-center text-sm-center text-md-center text-lg-center">
                <v-img :src="image.url" height="150" v-if="image.url" aspect-ratio="1" contain/>
                <v-text-field label="Select Image" @click='pickFile' v-model='image.name' prepend-icon='attach_file'></v-text-field>
                <input
                  type="file"
                  style="display: none"
                  ref="image"
                  accept="image/*"
                  @change="onFilePicked"
                >
              </v-flex>
              <v-btn color="primary" @click="create">
                <translate>Create category</translate>
              </v-btn>
            </v-form>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script lang="ts">
  import { CREATE_CATEGORY } from '@/graphql/category';
  import { Component, Vue } from 'vue-property-decorator';

  @Component
  export default class CreateCategory extends Vue {
    title = '';
    description = '';
    image = {
      url: '',
      name: '',
      file: '',
    };

    create() {
      this.$apollo.mutate({
        mutation: CREATE_CATEGORY,
        variables: {
          title: this.title,
          description: this.description,
          picture: (this.$refs['image'] as any).files[ 0 ],
        },
      }).then((data) => {
        console.log(data);
      }).catch((error) => {
        console.error(error);
      });
    }

    pickFile() {
      (this.$refs['image'] as any).click();
    }

    onFilePicked(e) {
      const files = e.target.files;
      if (files[ 0 ] === undefined || files[ 0 ].name.lastIndexOf('.') <= 0) {
        console.error('File is incorrect');
      }
      this.image.name = files[ 0 ].name;
    }

  };
</script>

<style>
  .markdown-render h1 {
    font-size: 2em;
  }
</style>
