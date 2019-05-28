<template>
  <section class="container">
    <h1 class="title">
      <translate>Create a new event</translate>
    </h1>
    <div v-if="$apollo.loading">Loading...</div>
    <div class="columns is-centered" v-else>
      <form class="column is-half" @submit="createEvent">
        <b-field :label="$gettext('Title')">
          <b-input aria-required="true" required v-model="event.title"/>
        </b-field>

        <b-datepicker v-model="event.beginsOn" inline></b-datepicker>

        <div class="field">
          <label class="label">{{ $gettext('Description') }}</label>
          <editor v-model="event.description" />
        </div>

        <b-field :label="$gettext('Category')">
          <b-select placeholder="Select a category" v-model="event.category">
            <option
              v-for="category in categories"
              :value="category"
              :key="category"
            >{{ $gettext(category) }}</option>
          </b-select>
        </b-field>

        <picture-upload @change="handlePictureUploadChange" />

        <button class="button is-primary">
          <translate>Create my event</translate>
        </button>
      </form>
    </div>
  </section>
</template>

<script lang="ts">
// import Location from '@/components/Location';
import { CREATE_EVENT, EDIT_EVENT } from '@/graphql/event';
import { Component, Prop, Vue } from 'vue-property-decorator';
import {
      Category,
      IEvent,
      EventModel,
    } from '@/types/event.model';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import PictureUpload from '@/components/PictureUpload.vue';
import { IPictureUpload } from '@/types/picture.model';
import Editor from '@/components/Editor.vue';

@Component({
  components: { PictureUpload, Editor },
  apollo: {
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
})
export default class CreateEvent extends Vue {
  @Prop({ required: false, type: String }) uuid!: string;

  loggedPerson: IPerson = new Person();
  categories: string[] = Object.keys(Category);
  event: IEvent = new EventModel();
  pictureFile?: File;
  pictureName?: String;

  createEvent(e: Event) {
    e.preventDefault();
    this.event.organizerActor = this.loggedPerson;
    this.event.attributedTo = this.loggedPerson;

    if (this.event.uuid === '') {
      console.log('event', this.event);
      this.$apollo
        .mutate({
          mutation: CREATE_EVENT,
          variables: {
            title: this.event.title,
            description: this.event.description,
            beginsOn: this.event.beginsOn.toISOString(),
            category: this.event.category,
            organizerActorId: this.event.organizerActor.id,
            picture_file: this.pictureFile,
            picture_name: this.pictureName,
          },
        })
        .then(data => {
          console.log('event created', data);
          this.$router.push({
            name: 'Event',
            params: { uuid: data.data.createEvent.uuid },
          });
        })
        .catch(error => {
          console.error(error);
        });
    } else {
      this.$apollo
        .mutate({
          mutation: EDIT_EVENT,
        })
        .then(data => {
          this.$router.push({
            name: 'Event',
            params: { uuid: data.data.uuid },
          });
        })
        .catch(error => {
          console.error(error);
        });
    }
  }

  handlePictureUploadChange(picture: IPictureUpload) {
    console.log('picture upload change', picture);
    this.pictureFile = picture.file;
    this.pictureName = picture.name;
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
