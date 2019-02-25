import {Category} from "../../types/event.model";
import {EventJoinOptions} from "../../types/event.model";
<template>
  <section>
    <h1 class="title">
      <translate>Create a new event</translate>
    </h1>
    <div v-if="$apollo.loading">Loading...</div>
    <div class="columns" v-else>
      <form class="column" @submit="createEvent">
        <b-field :label="$gettext('Title')">
          <b-input aria-required="true" required v-model="event.title"/>
        </b-field>

        <b-datepicker v-model="event.begins_on" inline></b-datepicker>

        <b-field :label="$gettext('Category')">
          <b-select placeholder="Select a category" v-model="event.category">
            <option
              v-for="category in categories"
              :value="category"
              :key="category"
            >{{ $gettext(category) }}</option>
          </b-select>
        </b-field>

        <button class="button is-primary">
          <translate>Create my event</translate>
        </button>
      </form>
    </div>
  </section>
</template>

<script lang="ts">
    // import Location from '@/components/Location';
    import VueMarkdown from "vue-markdown";
    import {CREATE_EVENT, EDIT_EVENT} from "@/graphql/event";
    import {Component, Prop, Vue} from "vue-property-decorator";
    import {Category, EventJoinOptions, EventStatus, EventVisibility, IEvent} from "@/types/event.model";
    import {LOGGED_PERSON} from "@/graphql/actor";
    import {IPerson} from "@/types/actor.model";

    @Component({
  components: {
    VueMarkdown
  }
})
export default class CreateEvent extends Vue {
  @Prop({ required: false, type: String }) uuid!: string;

  loggedPerson!: IPerson;
  categories: string[] = Object.keys(Category);
  event!: IEvent; // FIXME: correctly type an event

  // created() {
  //   if (this.uuid) {
  //     this.fetchEvent();
  //   }
  // }

  async created() {
    // We put initialization here because we need loggedPerson to be ready before initializing event
    const { data } = await this.$apollo.query({ query: LOGGED_PERSON });

    this.loggedPerson = data.loggedPerson;

    this.event = {
      title: "",
      organizerActor: this.loggedPerson,
      attributedTo: this.loggedPerson,
      description: "",
      begins_on: new Date(),
      ends_on: new Date(),
      category: Category.MEETING,
      participants: [],
      uuid: "",
      url: "",
      local: true,
      status: EventStatus.CONFIRMED,
      visibility: EventVisibility.PUBLIC,
      join_options: EventJoinOptions.FREE,
      thumbnail: "",
      large_image: "",
      publish_at: new Date()
    };
  }

  createEvent(e: Event) {
    e.preventDefault();

    if (this.uuid === undefined) {
      this.$apollo
        .mutate({
          mutation: CREATE_EVENT,
          variables: {
            title: this.event.title,
            description: this.event.description,
            beginsOn: this.event.begins_on,
            category: this.event.category,
            organizerActorId: this.event.organizerActor.id
          }
        })
        .then(data => {
          console.log("event created", data);
          this.$router.push({
            name: "Event",
            params: { uuid: data.data.createEvent.uuid }
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
          this.$router.push({
            name: "Event",
            params: { uuid: data.data.uuid }
          });
        })
        .catch(error => {
          console.log(error);
        });
    }
  }

  // getAddressData(addressData) {
  //   if (addressData !== null) {
  //     this.event.address = {
  //       geom: {
  //         data: {
  //           latitude: addressData.latitude,
  //           longitude: addressData.longitude
  //         },
  //         type: "point"
  //       },
  //       addressCountry: addressData.country,
  //       addressLocality: addressData.locality,
  //       addressRegion: addressData.administrative_area_level_1,
  //       postalCode: addressData.postal_code,
  //       streetAddress: `${addressData.street_number} ${addressData.route}`
  //     };
  //   }
  // }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
