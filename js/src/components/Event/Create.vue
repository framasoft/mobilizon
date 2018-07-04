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
              <v-text-field
                label="Title"
                v-model="event.title"
                :counter="100"
                required
              ></v-text-field>
              <v-radio-group v-model="event.location_type" row>
                <v-radio label="Address" value="physical" off-icon="place"></v-radio>
                <v-radio label="Online" value="online" off-icon="link"></v-radio>
                <v-radio label="Phone" value="phone" off-icon="phone"></v-radio>
                <v-radio label="Other" value="other"></v-radio>
              </v-radio-group>
              <vuetify-google-autocomplete
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
              </vuetify-google-autocomplete>
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
              >
              </v-autocomplete>
              <v-btn color="primary" @click="create">Create event</v-btn>
            </v-form>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
  // import Location from '@/components/Location';
  import eventFetch from '@/api/eventFetch';
  import VueMarkdown from 'vue-markdown';

  export default {
    name: 'create-event',
    props: ['id'],

    components: {
/*      Location,*/
      VueMarkdown,
    },
    data() {
      return {
        e1: 0,
        event: {
          title: null,
          description: null,
          begins_on: new Date(),
          ends_on: new Date(),
          seats: null,
          physical_address: null,
          location_type: 'physical',
          online_address: null,
          tel_num: null,
          price: null,
          category: null,
          category_id: null,
          tags: [],
          participants: [],
        },
        categories: [],
        tags: [],
        tagsToSend: [],
        tagsFetched: [],
      };
    },
    created() {
      if (this.id) {
        this.fetchEvent();
      }
    },
    mounted() {
      this.fetchCategories();
      this.fetchTags();
    },
    methods: {
      create() {
        // this.event.seats = parseInt(this.event.seats, 10);
        // this.tagsToSend.forEach((tag) => {
        //   this.event.tags.push({
        //     title: tag,
        //     // '@type': 'Tag',
        //   });
        // });
        this.event.category_id = this.event.category;
        this.event.organizer_actor_id = this.$store.state.user.actor.id;
        this.event.participants = [this.$store.state.user.actor.id];
        // this.event.price = parseFloat(this.event.price);

        if (this.id === undefined) {
          eventFetch('/events', this.$store, {method: 'POST', body: JSON.stringify({ event: this.event })})
            .then(response => response.json())
            .then((data) => {
              this.loading = false;
              this.$router.push({name: 'Event', params: {uuid: data.uuid}});
            }).catch((err) => {
              Promise.resolve(err).then((err) => {
                console.log('err creation', err);
              });
            });
        } else {
          eventFetch(`/events/${this.uuid}`, this.$store, {method: 'PUT', body: JSON.stringify(this.event)})
            .then(response => response.json())
            .then((data) => {
              this.loading = false;
              this.$router.push({name: 'Event', params: {uuid: data.uuid}});
            });
        }
        this.event.tags = [];
      },
      fetchCategories() {
        eventFetch('/categories', this.$store)
          .then(response => response.json())
          .then((response) => {
            this.loading = false;
            this.categories = response.data;
          });
      },
      fetchTags() {
        eventFetch('/tags', this.$store)
          .then(response => response.json())
          .then((response) => {
            this.loading = false;
            response.data.forEach((tag) => {
              this.tagsFetched.push(tag.name);
            });
          });
      },
      fetchEvent() {
        eventFetch(`/events/${this.id}`, this.$store)
          .then(response => response.json())
          .then((data) => {
            this.loading = false;
            this.event = data;
            console.log(this.event);
          });
      },
      getAddressData: function (addressData) {
        if (addressData !== null) {
            this.event.address = {
                geom: {
                    data: {
                        latitude: addressData.latitude,
                        longitude: addressData.longitude,
                    },
                    type: "point",
                },
                addressCountry: addressData.country,
                addressLocality: addressData.locality,
                addressRegion: addressData.administrative_area_level_1,
                postalCode: addressData.postal_code,
                streetAddress: `${addressData.street_number} ${addressData.route}`,
            };
        }
      },
    },
  };
</script>

<style>
  .markdown-render h1 {
    font-size: 2em;
  }
</style>
