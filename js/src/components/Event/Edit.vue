<template>
  <v-container fluid grid-list-md>
    <h3>Update event {{ event.title }}</h3>
    <v-progress-circular v-if="loading" indeterminate color="primary"></v-progress-circular>
    <v-form v-if="!loading">
      <v-stepper v-model="e1" vertical>
        <v-stepper-step step="1" :complete="e1 > 1">Basic Informations
          <small>Title and description</small>
        </v-stepper-step>
        <v-stepper-content step="1">
          <v-layout row wrap>
            <v-flex xs12>
              <v-text-field
                label="Title"
                v-model="event.title"
                :counter="100"
                required
              ></v-text-field>
            </v-flex>
            <v-flex md6>
              <v-text-field
                label="Description"
                v-model="event.description"
                multiLine
                required
              ></v-text-field>
            </v-flex>
            <v-flex md6>
              <vue-markdown class="markdown-render"
                            :watches="['show','html','breaks','linkify','emoji','typographer','toc']"
                            :source="event.description"
                            :show="true" :html="false" :breaks="true" :linkify="true"
                            :emoji="true" :typographer="true" :toc="false"
              ></vue-markdown>
            </v-flex>
            <v-flex md12>
              <v-select
                v-bind:items="categories"
                v-model="event.category"
                item-text="name"
                item-value="@id"
                label="Categories"
                single-line
                bottom
              ></v-select>
            </v-flex>
            <v-flex md12>
              <!--<v-text-field
                v-model="tagsToSend"
                label="Tags"
              ></v-text-field>-->
              <v-select
                v-model="tagsToSend"
                label="Tags"
                chips
                tags
                :items="tagsFetched"
              ></v-select>
            </v-flex>
          </v-layout>
          <v-btn color="primary" @click.native="e1 = 2">Next</v-btn>
        </v-stepper-content>
        <v-stepper-step step="2" :complete="e1 > 2">Date and place</v-stepper-step>
        <v-stepper-content step="2">
          Event starts at:
          <v-text-field type="datetime-local" v-model="event.startDate"></v-text-field>
          Event ends at:
          <v-text-field type="datetime-local" v-model="event.endDate"></v-text-field>

          <vuetify-google-autocomplete
            id="map"
            append-icon="search"
            placeholder="Start typing"
            label="Location"
            enable-geolocation
            v-on:placechanged="getAddressData"
          >
          </vuetify-google-autocomplete>
          <v-btn color="primary" @click.native="e1 = 3">Next</v-btn>
        </v-stepper-content>
        <v-stepper-step step="3" :complete="e1 > 3">Extra informations</v-stepper-step>
        <v-stepper-content step="3">
          <v-text-field
            label="Number of seats"
            v-model="event.seats"
          ></v-text-field>
          <v-text-field
            label="Price"
            prefix="$"
            type="float"
            v-model="event.price"
          ></v-text-field>
        </v-stepper-content>
      </v-stepper>
    </v-form>
    <v-btn color="primary" @click="create">Create event</v-btn>
  </v-container>
</template>

<script lang="ts">
  import { Component, Prop, Vue } from 'vue-property-decorator';

  @Component
  export default class EventEdit extends Vue {
    @Prop(String) id!: string;

    loading = true;
    event = null;

    created() {
      this.fetchData();
    }

    fetchData() {
      // FIXME: remove eventFetch
      // eventFetch(`/events/${this.id}`, this.$store)
      //   .then(response => response.json())
      //   .then((data) => {
      //     this.loading = false;
      //     this.event = data;
      //     console.log(this.event);
      //   });
    }
  };
</script>
