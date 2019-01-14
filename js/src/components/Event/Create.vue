<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Create a new event</v-toolbar-title>
          </v-toolbar>
          <v-card-text>
            <v-form>
              <v-text-field label="Title" v-model="event.title" :counter="100" required></v-text-field>
              <v-date-picker v-model="event.begins_on"></v-date-picker>
              <v-radio-group v-model="event.location_type" row>
                <v-radio label="Address" value="physical" off-icon="place"></v-radio>
                <v-radio label="Online" value="online" off-icon="link"></v-radio>
                <v-radio label="Phone" value="phone" off-icon="phone"></v-radio>
                <v-radio label="Other" value="other"></v-radio>
              </v-radio-group>
              <!-- <vuetify-google-autocomplete
                v-if="event.location_type === 'physical'"
                id="map"
                append-icon="search"
                classname="form-control"
                placeholder="Start typing"
                label="Location"
                enable-geolocation
                types="geocode"
                v-on:placechanged="getAddressData"
              >
              </vuetify-google-autocomplete>-->
              <v-text-field
                v-if="event.location_type === 'online'"
                label="Meeting adress"
                type="url"
                v-model="event.url"
                :required="event.location_type === 'online'"
              ></v-text-field>
              <v-text-field
                v-if="event.location_type === 'phone'"
                label="Phone number"
                type="tel"
                v-model="event.phone"
                :required="event.location_type === 'phone'"
              ></v-text-field>
              <v-autocomplete
                :items="categories"
                v-model="event.category"
                item-text="title"
                item-value="id"
                label="Categories"
              ></v-autocomplete>
              <v-btn color="primary" @click="create">Create event</v-btn>
            </v-form>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script lang="ts">
// import Location from '@/components/Location';
import VueMarkdown from "vue-markdown";
import { CREATE_EVENT, EDIT_EVENT } from "@/graphql/event";
import { FETCH_CATEGORIES } from "@/graphql/category";
import { AUTH_USER_ACTOR } from "@/constants";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component({
  components: {
    VueMarkdown
  },
  apollo: {
    categories: {
      query: FETCH_CATEGORIES
    }
  }
})
export default class CreateEvent extends Vue {
  @Prop({ required: false, type: String }) uuid!: string;

  e1 = 0;
  event = {
    title: null,
    organizer_actor_id: null,
    description: "",
    begins_on: new Date().toISOString().substr(0, 10),
    ends_on: new Date(),
    seats: null,
    physical_address: null,
    location_type: "physical",
    online_address: null,
    tel_num: null,
    price: null,
    category: null,
    category_id: null,
    tags: [],
    participants: []
  } as any; // FIXME: correctly type an event
  categories = [];
  tags = [];
  tagsToSend = [];
  tagsFetched = [];
  loading = false;

  // created() {
  //   if (this.uuid) {
  //     this.fetchEvent();
  //   }
  // }

  create() {
    // this.event.seats = parseInt(this.event.seats, 10);
    // this.tagsToSend.forEach((tag) => {
    //   this.event.tags.push({
    //     title: tag,
    //     // '@type': 'Tag',
    //   });
    // });
    // FIXME: correctly parse actor JSON
    const actor = JSON.parse(localStorage.getItem(AUTH_USER_ACTOR) || "{}");
    this.event.category_id = this.event.category;
    this.event.organizer_actor_id = actor.id;
    this.event.participants = [actor.id];
    // this.event.price = parseFloat(this.event.price);

    if (this.uuid === undefined) {
      this.$apollo
        .mutate({
          mutation: CREATE_EVENT,
          variables: {
            title: this.event.title,
            description: this.event.description,
            organizerActorId: this.event.organizer_actor_id,
            categoryId: this.event.category_id,
            beginsOn: this.event.begins_on
          }
        })
        .then(data => {
          this.loading = false;
          this.$router.push({
            name: "Event",
            params: { uuid: data.data.uuid }
          });
        })
        .catch(error => {
          console.log(error);
        });
    } else {
      this.$apollo
        .mutate({
          mutation: EDIT_EVENT
        })
        .then(data => {
          this.loading = false;
          this.$router.push({
            name: "Event",
            params: { uuid: data.data.uuid }
          });
        })
        .catch(error => {
          console.log(error);
        });
    }
    this.event.tags = [];
  }

  getAddressData(addressData) {
    if (addressData !== null) {
      this.event.address = {
        geom: {
          data: {
            latitude: addressData.latitude,
            longitude: addressData.longitude
          },
          type: "point"
        },
        addressCountry: addressData.country,
        addressLocality: addressData.locality,
        addressRegion: addressData.administrative_area_level_1,
        postalCode: addressData.postal_code,
        streetAddress: `${addressData.street_number} ${addressData.route}`
      };
    }
  }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
