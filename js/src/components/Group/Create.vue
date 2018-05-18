<template>
  <v-container>
    <h3>Create a new group</h3>
    <v-form>
      <v-layout row wrap>
        <v-flex xs12>
          <v-text-field
            label="Title"
            v-model="group.title"
            :counter="100"
            required
          ></v-text-field>
        </v-flex>
        <v-flex md6>
          <v-text-field
            label="Description"
            v-model="group.description"
            multiLine
            required
          ></v-text-field>
        </v-flex>
        <v-flex md6>
          <vue-markdown class="markdown-render"
                        :watches="['show','html','breaks','linkify','emoji','typographer','toc']"
                        :source="group.description"
                        :show="true" :html="false" :breaks="true" :linkify="true"
                        :emoji="true" :typographer="true" :toc="false"
          ></vue-markdown>
        </v-flex>
        <v-flex md12>
          <vuetify-google-autocomplete
            id="map"
            append-icon="search"
            classname="form-control"
            placeholder="Start typing"
            enable-geolocation
            v-on:placechanged="getAddressData"
          >
          </vuetify-google-autocomplete>
        </v-flex>
        <v-flex md12>
          <v-select
            v-bind:items="categories"
            v-model="group.category"
            item-text="title"
            item-value="@id"
            label="Categories"
            single-line
            bottom
            types="(cities)"
          ></v-select>
        </v-flex>
      </v-layout>
    </v-form>
    <v-btn color="primary" @click="create">Create group</v-btn>
  </v-container>
</template>

<script>
  import eventFetch from '@/api/eventFetch';
  import VueMarkdown from 'vue-markdown';
  import VuetifyGoogleAutocomplete from 'vuetify-google-autocomplete';

  export default {
    name: 'create-group',

    components: {
      VueMarkdown,
      VuetifyGoogleAutocomplete,
    },
    data() {
      return {
        e1: 0,
        group: {
          title: '',
          description: '',
          category: null,
        },
        categories: [],
      };
    },
    mounted() {
      this.fetchCategories();
    },
    methods: {
      create() {
        // this.group.organizer = "/accounts/" + this.$store.state.user.id;

        eventFetch('/groups', this.$store, { method: 'POST', body: JSON.stringify({group: this.group}) })
          .then(response => response.json())
          .then((data) => {
            this.loading = false;
            this.$router.push({ path: 'Group', params: { id: data.id } });
          });
      },
      fetchCategories() {
        eventFetch('/categories', this.$store)
          .then(response => response.json())
          .then((data) => {
            this.loading = false;
            this.categories = data.data;
          });
      },
      getAddressData: function (addressData) {
        this.group.address = {
          geo: {
            latitude: addressData.latitude,
            longitude: addressData.longitude,
          },
          addressCountry: addressData.country,
          addressLocality: addressData.city,
          addressRegion: addressData.administrative_area_level_1,
          postalCode: addressData.postal_code,
          streetAddress: `${addressData.street_number} ${addressData.route}`,
        };
      },
    },
  };
</script>

<style>
  .markdown-render h1 {
    font-size: 2em;
  }
</style>
