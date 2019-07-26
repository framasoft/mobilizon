<template>
  <section class="container">
    <h1 class="title">
      <translate>Create a new event</translate>
    </h1>
    <div v-if="$apollo.loading">Loading...</div>
    <div class="columns is-centered" v-else>
      <form class="column is-two-thirds-desktop" @submit="createEvent">
        <picture-upload v-model="pictureFile" />

        <b-field :label="$gettext('Title')">
          <b-input aria-required="true" required v-model="event.title" maxlength="64" />
        </b-field>

        <tag-input v-model="event.tags" :data="tags" path="title" />

        <date-time-picker v-model="event.beginsOn" :label="$gettext('Starts on…')" :step="15"/>
        <date-time-picker v-model="event.endsOn" :label="$gettext('Ends on…')" :step="15" />

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
import Editor from '@/components/Editor.vue';
import DateTimePicker from '@/components/Event/DateTimePicker.vue';
import TagInput from '@/components/Event/TagInput.vue';
import { TAGS } from '@/graphql/tags';
import { ITag } from '@/types/tag.model';

@Component({
  components: { TagInput, DateTimePicker, PictureUpload, Editor },
  apollo: {
    loggedPerson: {
      query: LOGGED_PERSON,
    },
    tags: {
      query: TAGS,
    },
  },
})
export default class CreateEvent extends Vue {
  @Prop({ required: false, type: String }) uuid!: string;

  loggedPerson: IPerson = new Person();
  categories: string[] = Object.keys(Category);
  event: IEvent = new EventModel();
  pictureFile: File | null = null;

  created() {
    const now = new Date();
    const end = new Date();
    end.setUTCHours(now.getUTCHours() + 3);
    this.event.beginsOn = now;
    this.event.endsOn = end;
  }

  createEvent(e: Event) {
    e.preventDefault();


    if (this.event.uuid === '') {
      console.log('event', this.event);
      this.$apollo
        .mutate({
          mutation: CREATE_EVENT,
          variables: this.buildVariables(),
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

  /**
   * Build variables for Event GraphQL creation query
   */
  private buildVariables() {
    /**
     * Transform general variables
     */
    let pictureObj = {};
    const obj = {
      organizerActorId: this.loggedPerson.id,
      beginsOn: this.event.beginsOn.toISOString(),
      tags: this.event.tags.map((tag: ITag) => tag.title),
    };
    const res = Object.assign({}, this.event, obj);

    /**
     * Transform picture files
     */
    if (this.pictureFile) {
      pictureObj = {
        picture: {
          picture: {
            name: this.pictureFile.name,
            file: this.pictureFile,
          },
        },
      };
    }

    return Object.assign({}, res, pictureObj);
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
