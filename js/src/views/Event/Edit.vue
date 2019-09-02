<template>
  <section class="container">
    <h1 class="title">
      <translate v-if="isUpdate === false">Create a new event</translate>
      <translate v-else>Update event {{ event.name }}</translate>
    </h1>

    <div v-if="$apollo.loading">Loading...</div>

    <div class="columns is-centered" v-else>
      <form class="column is-two-thirds-desktop" @submit="createOrUpdate">
        <h2 class="subtitle">
          <translate>
            General information
          </translate>
        </h2>
        <picture-upload v-model="pictureFile" />

        <b-field :label="$gettext('Title')">
          <b-input aria-required="true" required v-model="event.title" maxlength="64" />
        </b-field>

        <tag-input v-model="event.tags" :data="tags" path="title" />

        <address-auto-complete v-model="event.physicalAddress" />

        <date-time-picker v-model="event.beginsOn" :label="$gettext('Starts on…')" :step="15"/>
        <date-time-picker v-model="event.endsOn" :label="$gettext('Ends on…')" :step="15" />

        <div class="field">
          <label class="label">{{ $gettext('Description') }}</label>
          <editor v-model="event.description" />
        </div>

        <!--<b-field :label="$gettext('Category')">
          <b-select placeholder="Select a category" v-model="event.category">
            <option
              v-for="category in categories"
              :value="category"
              :key="category"
            >{{ $gettext(category) }}</option>
          </b-select>
        </b-field>-->

        <h2 class="subtitle">
          <translate>
            Visibility
          </translate>
        </h2>
          <label class="label">{{ $gettext('Event visibility') }}</label>
          <div class="field">
            <b-radio v-model="event.visibility" name="name" :native-value="EventVisibility.PUBLIC">
              <translate>Visible everywhere on the web (public)</translate>
            </b-radio>
          </div>
          <div class="field">
            <b-radio v-model="event.visibility" name="name" :native-value="EventVisibility.PRIVATE">
              <translate>Only accessible through link and search (private)</translate>
            </b-radio>
          </div>

          <button class="button is-primary">

          <translate v-if="isUpdate === false">Create my event</translate>
          <translate v-else>Update my event</translate>
        </button>
      </form>
    </div>
  </section>
</template>

<script lang="ts">
import { CREATE_EVENT, EDIT_EVENT, FETCH_EVENT } from '@/graphql/event';
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { EventModel, EventVisibility, IEvent } from '@/types/event.model';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import PictureUpload from '@/components/PictureUpload.vue';
import Editor from '@/components/Editor.vue';
import DateTimePicker from '@/components/Event/DateTimePicker.vue';
import TagInput from '@/components/Event/TagInput.vue';
import { TAGS } from '@/graphql/tags';
import { ITag } from '@/types/tag.model';
import AddressAutoComplete from '@/components/Event/AddressAutoComplete.vue';
import { buildFileFromIPicture, buildFileVariable } from '@/utils/image';

@Component({
  components: { AddressAutoComplete, TagInput, DateTimePicker, PictureUpload, Editor },
  apollo: {
    loggedPerson: {
      query: LOGGED_PERSON,
    },
    tags: {
      query: TAGS,
    },
  },
})
export default class EditEvent extends Vue {
  @Prop({ type: Boolean, default: false }) isUpdate!: boolean;
  @Prop({ required: false, type: String }) uuid!: string;

  eventId!: string | undefined;

  loggedPerson = new Person();
  event = new EventModel();
  pictureFile: File | null = null;

  EventVisibility = EventVisibility;

  // categories: string[] = Object.keys(Category);

  @Watch('$route.params.eventId', { immediate: true })
  async onEventIdParamChanged (val: string) {
    if (this.isUpdate !== true) return;

    this.eventId = val;

    if (this.eventId) {
      this.event = await this.getEvent();

      this.pictureFile = await buildFileFromIPicture(this.event.picture);
    }
  }

  created() {
    const now = new Date();
    const end = new Date();
    end.setUTCHours(now.getUTCHours() + 3);

    this.event.beginsOn = now;
    this.event.endsOn = end;
  }

  createOrUpdate(e: Event) {
    e.preventDefault();

    if (this.eventId) return this.updateEvent();

    return this.createEvent();
  }

  async createEvent() {
    try {
      const data = await this.$apollo.mutate({
        mutation: CREATE_EVENT,
        variables: this.buildVariables(),
      });

      console.log('Event created', data);

      this.$router.push({
        name: 'Event',
        params: { uuid: data.createEvent.uuid },
      });
    } catch (err) {
      console.error(err);
    }
  }

  async updateEvent() {
    try {
      await this.$apollo.mutate({
        mutation: EDIT_EVENT,
        variables: this.buildVariables(),
      });

      this.$router.push({
        name: 'Event',
        params: { uuid: this.eventId as string },
      });
    } catch (err) {
      console.error(err);
    }
  }

  /**
   * Build variables for Event GraphQL creation query
   */
  private buildVariables() {
    const obj = {
      organizerActorId: this.loggedPerson.id,
      beginsOn: this.event.beginsOn.toISOString(),
      tags: this.event.tags.map((tag: ITag) => tag.title),
    };
    const res = Object.assign({}, this.event, obj);

    if (this.event.physicalAddress) {
      delete this.event.physicalAddress['__typename'];
    }

    const pictureObj = buildFileVariable(this.pictureFile, 'picture');

    return Object.assign({}, res, pictureObj);
  }

  private async getEvent() {
    const result = await this.$apollo.query({
      query: FETCH_EVENT,
      variables: {
        uuid: this.eventId,
      },
    });

    return new EventModel(result.data.event);
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
