<template>
  <section>
    <h1 class="title">
      <translate>Create a new category</translate>
    </h1>
    <div class="columns">
      <form class="column" @submit="submit">
        <b-field :label="$gettext('Name of the category')">
          <b-input aria-required="true" required v-model="category.title"/>
        </b-field>

        <b-field :label="$gettext('Description')">
          <b-input type="textarea" v-model="category.description"/>
        </b-field>

        <b-field class="file">
          <b-upload v-model="file" @input="onFilePicked">
            <a class="button is-primary">
              <b-icon icon="upload"></b-icon>
              <span>
                <translate>Click to upload</translate>
              </span>
            </a>
          </b-upload>
          <span class="file-name" v-if="file">{{ this.image.name }}</span>
        </b-field>

        <button class="button is-primary">
          <translate>Create the category</translate>
        </button>
      </form>
    </div>
  </section>
</template>

<script lang="ts">
import { CREATE_CATEGORY } from "@/graphql/category";
import { Component, Vue } from "vue-property-decorator";
import { ICategory } from "@/types/event.model";

/**
 * TODO : No picture is uploaded ATM
 */

@Component
export default class CreateCategory extends Vue {
  category!: ICategory;
  image = {
    name: ""
  } as { name: string };
  file: any = null;

  create() {
    this.$apollo
      .mutate({
        mutation: CREATE_CATEGORY,
        variables: this.category
      })
      .then(data => {
        console.log(data);
      })
      .catch(error => {
        console.error(error);
      });
  }

  // TODO : Check if we can upload as soon as file is picked and purge files not validated
  onFilePicked(e) {
    if (e === undefined || e.name.lastIndexOf(".") <= 0) {
      console.error("File is incorrect");
    }
    this.image.name = e.name;
  }
}
</script>
