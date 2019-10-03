<template>
  <section>
    <div class="container">
      <h1 class="title" v-if="isUpdate === false">
        {{ $t('Create a new event') }}
      </h1>
      <h1 class="title" v-else>
        {{ $t('Update event {name}', { name: event.title }) }}
      </h1>

      <div class="columns is-centered">
        <form class="column is-two-thirds-desktop" ref="form">
          <h2 class="subtitle">
            {{ $t('General information') }}
          </h2>
          <picture-upload v-model="pictureFile" />

          <b-field :label="$t('Title')" :type="checkTitleLength[0]" :message="checkTitleLength[1]">
            <b-input aria-required="true" required v-model="event.title" />
          </b-field>

          <tag-input v-model="event.tags" :data="tags" path="title" />

          <date-time-picker v-model="event.beginsOn" :label="$t('Starts on…')" :step="15"/>
          <date-time-picker v-model="event.endsOn" :label="$t('Ends on…')" :step="15" />

          <address-auto-complete v-model="event.physicalAddress" />

          <b-field :label="$t('Organizer')">
            <identity-picker-wrapper v-model="event.organizerActor"></identity-picker-wrapper>
          </b-field>

          <div class="field">
            <label class="label">{{ $t('Description') }}</label>
            <editor v-model="event.description" />
          </div>

          <b-field :label="$t('Website / URL')">
            <b-input v-model="event.onlineAddress" placeholder="URL" />
          </b-field>

          <!--<b-field :label="$t('Category')">
            <b-select placeholder="Select a category" v-model="event.category">
              <option
                v-for="category in categories"
                :value="category"
                :key="category"
              >{{ $t(category) }}</option>
            </b-select>
          </b-field>-->

          <h2 class="subtitle">
            {{ $t('Who can view this event and participate') }}
          </h2>
            <div class="field">
              <b-radio v-model="event.visibility"
                       name="eventVisibility"
                       :native-value="EventVisibility.PUBLIC">
                {{ $t('Visible everywhere on the web (public)') }}
              </b-radio>
            </div>
            <div class="field">
              <b-radio v-model="event.visibility"
                       name="eventVisibility"
                       :native-value="EventVisibility.UNLISTED">
                {{ $t('Only accessible through link and search (private)') }}
              </b-radio>
            </div>
          <div class="field">
            <b-radio v-model="event.visibility"
                     name="eventVisibility"
                     :native-value="EventVisibility.PRIVATE">
               {{ $t('Page limited to my group (asks for auth)') }}
            </b-radio>
          </div>

          <div class="field">
            <label class="label">{{ $t('Participation approval') }}</label>
            <b-switch v-model="needsApproval">
              {{ $t('I want to approve every participation request') }}
            </b-switch>
          </div>

          <div class="field">
            <b-switch v-model="limitedPlaces">
              {{ $t('Limited places') }}
            </b-switch>
          </div>

          <div class="box" v-if="limitedPlaces">
            <b-field :label="$t('Number of places')">
              <b-numberinput v-model="event.options.maximumAttendeeCapacity"></b-numberinput>
            </b-field>

            <b-field>
              <b-switch v-model="event.options.showRemainingAttendeeCapacity">
                {{ $t('Show remaining number of places') }}
              </b-switch>
            </b-field>

            <b-field>
              <b-switch v-model="event.options.showParticipationPrice">
                {{ $t('Display participation price') }}
              </b-switch>
            </b-field>
          </div>

          <h2 class="subtitle">
            {{ $t('Public comment moderation') }}
          </h2>

          <label>{{ $t('Comments on the event page') }}</label>

          <div class="field">
            <b-radio v-model="event.options.commentModeration"
                     name="commentModeration"
                     :native-value="CommentModeration.ALLOW_ALL">
              {{ $t('Allow all comments') }}
            </b-radio>
          </div>

          <div class="field">
            <b-radio v-model="event.options.commentModeration"
                     name="commentModeration"
                     :native-value="CommentModeration.MODERATED">
              {{ $t('Moderated comments (shown after approval)') }}
            </b-radio>
          </div>

          <div class="field">
            <b-radio v-model="event.options.commentModeration"
                     name="commentModeration"
                     :native-value="CommentModeration.CLOSED">
              {{ $t('Close comments for all (except for admins)') }}
            </b-radio>
          </div>

          <h2 class="subtitle">
            {{ $t('Status') }}
          </h2>

          <div class="field">
            <b-radio v-model="event.status"
                     name="status"
                     :native-value="EventStatus.TENTATIVE">
              {{ $t('Tentative: Will be confirmed later') }}
            </b-radio>
          </div>

          <div class="field">
            <b-radio v-model="event.status"
                     name="status"
                     :native-value="EventStatus.CONFIRMED">
              {{ $t('Confirmed: Will happen') }}
            </b-radio>
          </div>
        </form>
      </div>
    </div>
    <span ref="bottomObserver"></span>
    <nav role="navigation" aria-label="main navigation" class="navbar" :class="{'is-fixed-bottom': showFixedNavbar }">
      <div class="container">
        <div class="navbar-menu">
          <div class="navbar-start">
            <span class="navbar-item" v-if="isEventModified">{{ $t('Unsaved changes') }}</span>
          </div>
          <div class="navbar-end">
            <span class="navbar-item">
              <b-button type="is-text" @click="confirmGoBack">
                {{ $t('Cancel') }}
              </b-button>
            </span>
            <!-- If an event has been published we can't make it draft anymore -->
            <span class="navbar-item" v-if="event.draft === true">
              <b-button type="is-primary" outlined @click="createOrUpdateDraft">
                {{ $t('Save draft') }}
              </b-button>
            </span>
            <span class="navbar-item">
              <b-button type="is-primary" @click="createOrUpdatePublish" @keyup.enter="createOrUpdatePublish">
                <span v-if="isUpdate === false">{{ $t('Create my event') }}</span>
                <span v-else-if="event.draft === true"> {{ $t('Publish') }}</span>
                <span v-else> {{ $t('Update my event') }}</span>
              </b-button>
            </span>
          </div>
        </div>
      </div>
    </nav>
  </section>
</template>

<style lang="scss" scoped>
  @import "@/variables.scss";

  h2.subtitle {
    margin: 10px 0;

    span {
      padding: 5px 7px;
      display: inline;
      background: $secondary;
    }
  }

  section {
    & > .container {
      margin-bottom: 2rem;
      padding: 1rem;
    }

    nav.navbar {
      min-height: 2rem !important;
      background: lighten($secondary, 10%);

      .container {
        min-height: 2rem;

        .navbar-menu, .navbar-end {
          display: flex !important;
          background: lighten($secondary, 10%);
        }

        .navbar-end {
          justify-content: flex-end;
          margin-left: auto;
        }
      }
    }
  }
</style>

<script lang="ts">
import { CREATE_EVENT, EDIT_EVENT, FETCH_EVENT } from '@/graphql/event';
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import {
  CommentModeration, EventJoinOptions,
  EventModel,
  EventStatus,
  EventVisibility, IEvent,
} from '@/types/event.model';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { IActor, Person } from '@/types/actor';
import PictureUpload from '@/components/PictureUpload.vue';
import Editor from '@/components/Editor.vue';
import DateTimePicker from '@/components/Event/DateTimePicker.vue';
import TagInput from '@/components/Event/TagInput.vue';
import { TAGS } from '@/graphql/tags';
import { ITag } from '@/types/tag.model';
import AddressAutoComplete from '@/components/Event/AddressAutoComplete.vue';
import { buildFileFromIPicture, buildFileVariable } from '@/utils/image';
import IdentityPickerWrapper from '@/views/Account/IdentityPickerWrapper.vue';

@Component({
  components: { IdentityPickerWrapper, AddressAutoComplete, TagInput, DateTimePicker, PictureUpload, Editor },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
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

  currentActor = new Person();
  tags: ITag[] = [];
  event: IEvent = new EventModel();
  unmodifiedEvent!: IEvent;
  pictureFile: File | null = null;

  EventStatus = EventStatus;
  EventVisibility = EventVisibility;
  needsApproval: boolean = false;
  canPromote: boolean = true;
  limitedPlaces: boolean = false;
  CommentModeration = CommentModeration;
  showFixedNavbar: boolean = true;
  observer!: IntersectionObserver;

  // categories: string[] = Object.keys(Category);

  @Watch('$route.params.eventId', { immediate: true })
  async onEventIdParamChanged (val: string) {
    if (!this.isUpdate) return;

    this.eventId = val;

    if (this.eventId) {
      this.event = await this.getEvent();
      this.unmodifiedEvent = JSON.parse(JSON.stringify(this.event.toEditJSON()));

      this.pictureFile = await buildFileFromIPicture(this.event.picture);
      this.limitedPlaces = this.event.options.maximumAttendeeCapacity != null;
    }
  }

  created() {
    this.initializeEvent();
    this.unmodifiedEvent = JSON.parse(JSON.stringify(this.event.toEditJSON()));
  }

  private initializeEvent() {
    const roundUpTo = roundTo => x => new Date(Math.ceil(x / roundTo) * roundTo);
    const roundUpTo15Minutes = roundUpTo(1000 * 60 * 15);

    const now = roundUpTo15Minutes(new Date());
    const end = roundUpTo15Minutes(new Date());
    end.setUTCHours(now.getUTCHours() + 3);

    this.event.beginsOn = now;
    this.event.endsOn = end;
    this.event.organizerActor = this.event.organizerActor || this.currentActor;
  }

  mounted() {
    this.observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry) {
          this.showFixedNavbar = !entry.isIntersecting;
        }
      }
    },                                       {
      rootMargin: '-50px 0px -50px',
    });
    this.observer.observe(this.$refs.bottomObserver as Element);
  }

  createOrUpdateDraft(e: Event) {
    e.preventDefault();
    if (this.validateForm()) {
      if (this.eventId) return this.updateEvent();

      return this.createEvent();
    }
  }

  createOrUpdatePublish(e: Event) {
    if (this.validateForm()) {
      this.event.draft = false;
      this.createOrUpdateDraft(e);
    }
  }

  private validateForm() {
    const form = this.$refs.form as HTMLFormElement;
    if (form.checkValidity()) {
      return true;
    }
    form.reportValidity();
    return false;
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
    let res = this.event.toEditJSON();
    if (this.event.organizerActor) {
      res = Object.assign(res, { organizerActorId: this.event.organizerActor.id });
    }

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

  @Watch('needsApproval')
  updateEventJoinOptions(needsApproval) {
    if (needsApproval === true) {
      this.event.joinOptions = EventJoinOptions.RESTRICTED;
    } else {
      this.event.joinOptions = EventJoinOptions.FREE;
    }
  }

  get checkTitleLength() {
    return this.event.title.length > 80 ? ['is-info', this.$t('The event title will be ellipsed.')] : [undefined, undefined];
  }

  /**
   * Confirm cancel
   */
  confirmGoBack() {
    if (!this.isEventModified) {
      return this.$router.go(-1);
    }
    const title: string = this.isUpdate ?
            this.$t('Cancel edition') as string :
            this.$t('Cancel creation') as string;
    const message: string = this.isUpdate ?
            this.$t("Are you sure you want to cancel the event edition? You'll lose all modifications.",
                    { title: this.event.title }) as string :
            this.$t("Are you sure you want to cancel the event creation? You'll lose all modifications.",
                    { title: this.event.title }) as string;

    this.$buefy.dialog.confirm({
      title,
      message,
      confirmText: this.$t('Cancel') as string,
      cancelText: this.$t('Continue editing') as string,
      type: 'is-warning',
      hasIcon: true,
      onConfirm: () => this.$router.go(-1),
    });
  }

  get isEventModified(): boolean {
    return JSON.stringify(this.event.toEditJSON()) !== JSON.stringify(this.unmodifiedEvent);
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

