<template>
  <v-container fluid grid-list-md>
    <h3>Create a new event</h3>
    <v-form>
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
                item-text="title"
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
          <v-text-field type="datetime-local" v-model="event.begins_on"></v-text-field>
          <!--<v-layout row wrap>
            <v-flex md6>
              <v-dialog
                persistent
                v-model="modals.beginning.date"
                lazy
                full-width
              >
                <v-text-field
                  slot="activator"
                  label="Beginning of the event date"
                  v-model="event.startDate.date"
                  prepend-icon="event"
                  readonly
                ></v-text-field>
                <v-date-picker v-model="event.startDate.date" scrollable dateFormat="val => new Date(val).">
                  <template scope="{ save, cancel }">
                    <v-card-actions>
                      <v-btn flat primary @click.native="cancel()">Cancel</v-btn>
                      <v-btn flat primary @click.native="save()">Save</v-btn>
                    </v-card-actions>
                  </template>
                </v-date-picker>
              </v-dialog>
            </v-flex>
            <v-flex md6>
              <v-dialog
                persistent
                v-model="modals.beginning.time"
                lazy
              >
                <v-text-field
                  slot="activator"
                  label="Beginning of the event time"
                  v-model="event.startDate.time"
                  prepend-icon="access_time"
                  readonly
                ></v-text-field>
                <v-time-picker v-model="event.startDate.time" actions format="24h">
                  <template scope="{ save, cancel }">
                    <v-card-actions>
                      <v-btn flat primary @click.native="cancel()">Cancel</v-btn>
                      <v-btn flat primary @click.native="save()">Save</v-btn>
                    </v-card-actions>
                  </template>
                </v-time-picker>
              </v-dialog>
            </v-flex>
          </v-layout>-->
          Event ends at:
          <v-text-field type="datetime-local" v-model="event.ends_on"></v-text-field>
          <!--<v-layout row wrap>
            <v-flex md6>
              <v-dialog
                persistent
                v-model="modals.end.date"
                lazy
                full-width
              >
                <v-text-field
                  slot="activator"
                  label="End of the event date"
                  v-model="event.endDate.date"
                  prepend-icon="event"
                  readonly
                ></v-text-field>
                <v-date-picker v-model="event.endDate.date" scrollable >
                  <template scope="{ save, cancel }">
                    <v-card-actions>
                      <v-btn flat primary @click.native="cancel()">Cancel</v-btn>
                      <v-btn flat primary @click.native="save()">Save</v-btn>
                    </v-card-actions>
                  </template>
                </v-date-picker>
              </v-dialog>
            </v-flex>
            <v-flex md6>
              <v-dialog
                persistent
                v-model="modals.end.time"
                lazy
              >
                <v-text-field
                  slot="activator"
                  label="End of the event time"
                  v-model="event.endDate.time"
                  prepend-icon="access_time"
                  readonly
                ></v-text-field>
                <v-time-picker v-model="event.endDate.time" format="24h" actions >
                  <template scope="{ save, cancel }">
                    <v-card-actions>
                      <v-btn flat primary @click.native="cancel()">Cancel</v-btn>
                      <v-btn flat primary @click.native="save()">Save</v-btn>
                    </v-card-actions>
                  </template>
                </v-time-picker>
              </v-dialog>
            </v-flex>
          </v-layout>-->

          <vuetify-google-autocomplete
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
          title: '',
          description: '',
          begins_on: new Date(),
          ends_on: new Date(),
          seats: 0,
          address: {
            description: null,
            floor: null,
            geo: {
              type: null,
              data: {
                latitude: null,
                longitude: null,
              },
            },
            addressCountry: null,
            addressLocality: null,
            addressRegion: null,
            postalCode: null,
            streetAddress: null,
          },
          price: 0,
          category: null,
          tags: [],
          participants: [],
        },
        categories: [],
        tags: [{ name: 'test' }, { name: 'montag' }],
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
        this.event.seats = parseInt(this.event.seats, 10);
        this.tagsToSend.forEach((tag) => {
          this.event.tags.push({
            name: tag,
            // '@type': 'Tag',
          });
        });
        this.event.category_id = this.event.category.id;
        this.event.organizer_account_id = this.$store.state.user.account.id;
        this.event.participants = [this.$store.state.user.account.id];
        this.event.price = parseFloat(this.event.price);

        if (this.id === undefined) {
          eventFetch('/events', this.$store, {method: 'POST', body: JSON.stringify({ event: this.event })})
            .then(response => response.json())
            .then((data) => {
              this.loading = false;
              this.$router.push({name: 'Event', params: {id: data.id}});
            });
        } else {
          eventFetch(`/events/${this.id}`, this.$store, {method: 'PUT', body: JSON.stringify(this.event)})
            .then(response => response.json())
            .then((data) => {
              this.loading = false;
              this.$router.push({name: 'Event', params: {id: data.id}});
            });
        }
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
