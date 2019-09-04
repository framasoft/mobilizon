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

        <b-field :label="$gettext('Website / URL')">
          <b-input v-model="event.onlineAddress" placeholder="URL" />
        </b-field>

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
            Who can view this event and participate
          </translate>
        </h2>
          <div class="field">
            <b-radio v-model="eventVisibilityJoinOptions"
                     name="eventVisibilityJoinOptions"
                     :native-value="EventVisibilityJoinOptions.PUBLIC">
              <translate>Visible everywhere on the web (public)</translate>
            </b-radio>
          </div>
          <div class="field">
            <b-radio v-model="eventVisibilityJoinOptions"
                     name="eventVisibilityJoinOptions"
                     :native-value="EventVisibilityJoinOptions.LINK">
              <translate>Only accessible through link and search (private)</translate>
            </b-radio>
          </div>
        <div class="field">
          <b-radio v-model="eventVisibilityJoinOptions"
                   name="eventVisibilityJoinOptions"
                   :native-value="EventVisibilityJoinOptions.LIMITED">
            <translate>Page limited to my group (asks for auth)</translate>
          </b-radio>
        </div>

        <div class="field">
          <label class="label">Approbation des participations</label>
          <b-switch v-model="needsApproval">
            Je veux approuver chaque demande de participation
          </b-switch>
        </div>

        <div class="field">
          <label class="label">Mise en avant</label>
          <b-switch v-model="doNotPromote" :disabled="canPromote === false">
            Ne pas autoriser la mise en avant sur sur Mobilizon
          </b-switch>
        </div>

        <div class="field">
          <b-switch v-model="limitedPlaces">
            Places limitées
          </b-switch>
        </div>

        <div class="box" v-if="limitedPlaces">
          <b-field label="Number of places">
            <b-numberinput v-model="event.options.maximumAttendeeCapacity"></b-numberinput>
          </b-field>

          <b-field>
            <b-switch v-model="event.options.showRemainingAttendeeCapacity">
              Show remaining number of places
            </b-switch>
          </b-field>

          <b-field>
            <b-switch v-model="event.options.showParticipationPrice">
              Display participation price
            </b-switch>
          </b-field>
        </div>

        <h2 class="subtitle">
          <translate>
            Modération des commentaires publics
          </translate>
        </h2>

        <label>Comments on the event page</label>

        <div class="field">
          <b-radio v-model="event.options.commentModeration"
                   name="commentModeration"
                   :native-value="CommentModeration.ALLOW_ALL">
            <translate>Allow all comments</translate>
          </b-radio>
        </div>

        <div class="field">
          <b-radio v-model="event.options.commentModeration"
                   name="commentModeration"
                   :native-value="CommentModeration.MODERATED">
            <translate>Moderated comments (shown after approval)</translate>
          </b-radio>
        </div>

        <div class="field">
          <b-radio v-model="event.options.commentModeration"
                   name="commentModeration"
                   :native-value="CommentModeration.CLOSED">
            <translate>Close all comments (except for admins)</translate>
          </b-radio>
        </div>

        <h2 class="subtitle">
          <translate>
            Status
          </translate>
        </h2>

        <div class="field">
          <b-radio v-model="event.status"
                   name="status"
                   :native-value="EventStatus.TENTATIVE">
            <translate>Tentative: Will be confirmed later</translate>
          </b-radio>
        </div>

        <div class="field">
          <b-radio v-model="event.status"
                   name="status"
                   :native-value="EventStatus.CONFIRMED">
            <translate>Confirmed: Will happen</translate>
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
import { EventModel, EventStatus, EventVisibility, EventVisibilityJoinOptions, CommentModeration } from '@/types/event.model';
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
  tags: ITag[] = [];
  event = new EventModel();
  pictureFile: File | null = null;

  EventStatus = EventStatus;
  EventVisibilityJoinOptions = EventVisibilityJoinOptions;
  eventVisibilityJoinOptions: EventVisibilityJoinOptions = EventVisibilityJoinOptions.PUBLIC;
  needsApproval: boolean = false;
  doNotPromote: boolean = false;
  canPromote: boolean = true;
  limitedPlaces: boolean = false;
  CommentModeration = CommentModeration;

  // categories: string[] = Object.keys(Category);

  @Watch('$route.params.eventId', { immediate: true })
  async onEventIdParamChanged (val: string) {
    if (!this.isUpdate) return;

    this.eventId = val;

    if (this.eventId) {
      this.event = await this.getEvent();

      this.pictureFile = await buildFileFromIPicture(this.event.picture);
      this.limitedPlaces = this.event.options.maximumAttendeeCapacity != null;
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
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_EVENT,
        variables: this.buildVariables(),
      });

      console.log('Event created', data);

      await this.$router.push({
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

      await this.$router.push({
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

    delete this.event.options['__typename'];

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

  @Watch('eventVisibilityJoinOptions')
  calculateVisibilityAndJoinOptions(eventVisibilityJoinOptions) {
    switch (eventVisibilityJoinOptions) {
      case EventVisibilityJoinOptions.PUBLIC:
        this.event.visibility = EventVisibility.UNLISTED;
        this.canPromote = true;
        break;
      case EventVisibilityJoinOptions.LINK:
        this.event.visibility = EventVisibility.PRIVATE;
        this.canPromote = false;
        this.doNotPromote = false;
        break;
      case EventVisibilityJoinOptions.LIMITED:
        this.event.visibility = EventVisibility.RESTRICTED;
        this.canPromote = false;
        this.doNotPromote = false;
        break;
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
<style lang="scss">
  @import "@/variables.scss";

  h2.subtitle {
    margin: 10px 0;

    span {
      padding: 5px 7px;
      display: inline;
      background: $secondary;
    }
  }
</style>
