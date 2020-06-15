<template>
  <section>
    <div class="container">
      <h1 class="title" v-if="isUpdate === true">
        {{ $t("Update event {name}", { name: event.title }) }}
      </h1>
      <h1 class="title" v-else>
        {{ $t("Create a new event") }}
      </h1>

      <form ref="form">
        <subtitle>{{ $t("General information") }}</subtitle>
        <picture-upload v-model="pictureFile" :textFallback="$t('Headline picture')" />

        <b-field :label="$t('Title')" :type="checkTitleLength[0]" :message="checkTitleLength[1]">
          <b-input size="is-large" aria-required="true" required v-model="event.title" />
        </b-field>

        <tag-input v-model="event.tags" :data="tags" path="title" />

        <date-time-picker v-model="event.beginsOn" :label="$t('Starts on…')" />
        <date-time-picker
          :min-datetime="event.beginsOn"
          v-model="event.endsOn"
          :label="$t('Ends on…')"
        />
        <!--          <b-switch v-model="endsOnNull">{{ $t('No end date') }}</b-switch>-->
        <b-button type="is-text" @click="dateSettingsIsOpen = true">
          {{ $t("Date parameters") }}
        </b-button>

        <address-auto-complete v-model="event.physicalAddress" />

        <div class="field">
          <label class="label">{{ $t("Description") }}</label>
          <editor v-model="event.description" />
        </div>

        <b-field :label="$t('Website / URL')">
          <b-input icon="link" type="url" v-model="event.onlineAddress" placeholder="URL" />
        </b-field>

        <subtitle>{{ $t("Organizers") }}</subtitle>
        <div class="columns">
          <div class="column">
            <b-field :label="$t('Organizer')">
              <identity-picker-wrapper
                v-model="event.organizerActor"
                :masked="event.options.hideOrganizerWhenGroupEvent"
                @input="resetAttributedToOnOrganizerChange"
              />
            </b-field>
          </div>
          <div class="column" v-if="config && config.features.groups">
            <b-field :label="$t('Group')" v-if="event.organizerActor">
              <group-picker-wrapper v-model="event.attributedTo" :identity="event.organizerActor" />
            </b-field>
          </div>
        </div>
        <!--        <div class="field" v-if="event.attributedTo.id">-->
        <!--          <label class="label">{{ $t('Hide the organizer') }}</label>-->
        <!--          <b-switch v-model="event.options.hideOrganizerWhenGroupEvent">-->
        <!--            {{ $t("Don't show @{organizer} as event host alongside @{group}", {organizer: event.organizerActor.preferredUsername, group: event.attributedTo.preferredUsername}) }}-->
        <!--            <small>-->
        <!--              <br>-->
        <!--              {{ $t('All group members and other eventual server admins will still be able to view this information.') }}-->
        <!--            </small>-->
        <!--          </b-switch>-->
        <!--        </div>-->

        <!--<b-field :label="$t('Category')">
          <b-select placeholder="Select a category" v-model="event.category">
            <option
              v-for="category in categories"
              :value="category"
              :key="category"
            >{{ $t(category) }}</option>
          </b-select>
        </b-field>-->

        <subtitle>{{ $t("Who can view this event and participate") }}</subtitle>
        <div class="field">
          <b-radio
            v-model="event.visibility"
            name="eventVisibility"
            :native-value="EventVisibility.PUBLIC"
            >{{ $t("Visible everywhere on the web (public)") }}</b-radio
          >
        </div>
        <div class="field">
          <b-radio
            v-model="event.visibility"
            name="eventVisibility"
            :native-value="EventVisibility.UNLISTED"
            >{{ $t("Only accessible through link and search (private)") }}</b-radio
          >
        </div>
        <!-- <div class="field">
          <b-radio v-model="event.visibility"
                   name="eventVisibility"
                   :native-value="EventVisibility.PRIVATE">
             {{ $t('Page limited to my group (asks for auth)') }}
          </b-radio>
        </div>-->

        <div class="field" v-if="config && config.anonymous.participation.allowed">
          <label class="label">{{ $t("Anonymous participations") }}</label>
          <b-switch v-model="event.options.anonymousParticipation">
            {{ $t("I want to allow people to participate without an account.") }}
            <small v-if="config.anonymous.participation.validation.email.confirmationRequired">
              <br />
              {{
                $t(
                  "Anonymous participants will be asked to confirm their participation through e-mail."
                )
              }}
            </small>
          </b-switch>
        </div>

        <div class="field">
          <label class="label">{{ $t("Participation approval") }}</label>
          <b-switch v-model="needsApproval">{{
            $t("I want to approve every participation request")
          }}</b-switch>
        </div>

        <div class="field">
          <label class="label">{{ $t("Number of places") }}</label>
          <b-switch v-model="limitedPlaces">{{ $t("Limited number of places") }}</b-switch>
        </div>

        <div class="box" v-if="limitedPlaces">
          <b-field :label="$t('Number of places')">
            <b-numberinput
              controls-position="compact"
              min="1"
              v-model="event.options.maximumAttendeeCapacity"
            />
          </b-field>
          <!--
          <b-field>
            <b-switch v-model="event.options.showRemainingAttendeeCapacity">
              {{ $t('Show remaining number of places') }}
            </b-switch>
          </b-field>

          <b-field>
            <b-switch v-model="event.options.showParticipationPrice">
              {{ $t('Display participation price') }}
            </b-switch>
          </b-field>-->
        </div>

        <subtitle>{{ $t("Public comment moderation") }}</subtitle>

        <div class="field">
          <b-radio
            v-model="event.options.commentModeration"
            name="commentModeration"
            :native-value="CommentModeration.ALLOW_ALL"
            >{{ $t("Allow all comments") }}</b-radio
          >
        </div>

        <!--          <div class="field">-->
        <!--            <b-radio v-model="event.options.commentModeration"-->
        <!--                     name="commentModeration"-->
        <!--                     :native-value="CommentModeration.MODERATED">-->
        <!--              {{ $t('Moderated comments (shown after approval)') }}-->
        <!--            </b-radio>-->
        <!--          </div>-->

        <div class="field">
          <b-radio
            v-model="event.options.commentModeration"
            name="commentModeration"
            :native-value="CommentModeration.CLOSED"
            >{{ $t("Close comments for all (except for admins)") }}</b-radio
          >
        </div>

        <subtitle>{{ $t("Status") }}</subtitle>

        <b-field>
          <b-radio-button
            v-model="event.status"
            name="status"
            type="is-warning"
            :native-value="EventStatus.TENTATIVE"
          >
            <b-icon icon="calendar-question" />
            {{ $t("Tentative: Will be confirmed later") }}
          </b-radio-button>
          <b-radio-button
            v-model="event.status"
            name="status"
            type="is-success"
            :native-value="EventStatus.CONFIRMED"
          >
            <b-icon icon="calendar-check" />
            {{ $t("Confirmed: Will happen") }}
          </b-radio-button>
          <b-radio-button
            v-model="event.status"
            name="status"
            type="is-danger"
            :native-value="EventStatus.CANCELLED"
          >
            <b-icon icon="calendar-remove" />
            {{ $t("Cancelled: Won't happen") }}
          </b-radio-button>
        </b-field>
      </form>
    </div>
    <b-modal :active.sync="dateSettingsIsOpen" has-modal-card trap-focus>
      <form action>
        <div class="modal-card" style="width: auto;">
          <header class="modal-card-head">
            <p class="modal-card-title">{{ $t("Date and time settings") }}</p>
          </header>
          <section class="modal-card-body">
            <b-field :label="$t('Event page settings')">
              <b-switch v-model="event.options.showStartTime">{{
                $t("Show the time when the event begins")
              }}</b-switch>
            </b-field>
            <b-field>
              <b-switch v-model="event.options.showEndTime">{{
                $t("Show the time when the event ends")
              }}</b-switch>
            </b-field>
          </section>
          <footer class="modal-card-foot">
            <button class="button" type="button" @click="dateSettingsIsOpen = false">
              {{ $t("OK") }}
            </button>
          </footer>
        </div>
      </form>
    </b-modal>
    <span ref="bottomObserver" />
    <nav
      role="navigation"
      aria-label="main navigation"
      class="navbar"
      :class="{ 'is-fixed-bottom': showFixedNavbar }"
    >
      <div class="container">
        <div class="navbar-menu">
          <div class="navbar-start">
            <span class="navbar-item" v-if="isEventModified">{{ $t("Unsaved changes") }}</span>
          </div>
          <div class="navbar-end">
            <span class="navbar-item">
              <b-button type="is-text" @click="confirmGoBack">{{ $t("Cancel") }}</b-button>
            </span>
            <!-- If an event has been published we can't make it draft anymore -->
            <span class="navbar-item" v-if="event.draft === true">
              <b-button type="is-primary" outlined @click="createOrUpdateDraft">{{
                $t("Save draft")
              }}</b-button>
            </span>
            <span class="navbar-item">
              <b-button
                type="is-primary"
                @click="createOrUpdatePublish"
                @keyup.enter="createOrUpdatePublish"
              >
                <span v-if="isUpdate === false">{{ $t("Create my event") }}</span>
                <span v-else-if="event.draft === true">{{ $t("Publish") }}</span>
                <span v-else>{{ $t("Update my event") }}</span>
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

main section > .container {
  background: $white;
}

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
    padding: 2rem 1.5rem;
  }

  nav.navbar {
    min-height: 2rem !important;
    background: lighten($secondary, 10%);

    .container {
      min-height: 2rem;

      .navbar-menu,
      .navbar-end {
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
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import PictureUpload from "@/components/PictureUpload.vue";
import EditorComponent from "@/components/Editor.vue";
import DateTimePicker from "@/components/Event/DateTimePicker.vue";
import TagInput from "@/components/Event/TagInput.vue";
import AddressAutoComplete from "@/components/Event/AddressAutoComplete.vue";
import IdentityPickerWrapper from "@/views/Account/IdentityPickerWrapper.vue";
import Subtitle from "@/components/Utils/Subtitle.vue";
import GroupPickerWrapper from "@/components/Group/GroupPickerWrapper.vue";
import { Route } from "vue-router";
import {
  CREATE_EVENT,
  EDIT_EVENT,
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
} from "../../graphql/event";
import {
  CommentModeration,
  EventJoinOptions,
  EventModel,
  EventStatus,
  EventVisibility,
  IEvent,
  ParticipantRole,
} from "../../types/event.model";
import {
  CURRENT_ACTOR_CLIENT,
  LOGGED_USER_DRAFTS,
  LOGGED_USER_PARTICIPATIONS,
} from "../../graphql/actor";
import { Group, IPerson, Person } from "../../types/actor";
import { TAGS } from "../../graphql/tags";
import { ITag } from "../../types/tag.model";
import { buildFileFromIPicture, buildFileVariable, readFileAsync } from "../../utils/image";
import RouteName from "../../router/name";
import "intersection-observer";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";

const DEFAULT_LIMIT_NUMBER_OF_PLACES = 10;

@Component({
  components: {
    GroupPickerWrapper,
    Subtitle,
    IdentityPickerWrapper,
    AddressAutoComplete,
    TagInput,
    DateTimePicker,
    PictureUpload,
    Editor: EditorComponent,
  },
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    tags: TAGS,
    config: CONFIG,
    event: {
      query: FETCH_EVENT,
      variables() {
        return {
          uuid: this.eventId,
        };
      },
      update(data) {
        return new EventModel(data.event);
      },
      skip() {
        return !this.eventId;
      },
    },
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // @ts-ignore
      title: (this.isUpdate ? this.$t("Event edition") : this.$t("Event creation")) as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class EditEvent extends Vue {
  @Prop({ required: false, type: String }) eventId: undefined | string;

  @Prop({ type: Boolean, default: false }) isUpdate!: boolean;

  @Prop({ type: Boolean, default: false }) isDuplicate!: boolean;

  currentActor = new Person();

  tags: ITag[] = [];

  event: IEvent = new EventModel();

  config!: IConfig;

  unmodifiedEvent!: IEvent;

  pictureFile: File | null = null;

  EventStatus = EventStatus;

  EventVisibility = EventVisibility;

  needsApproval = false;

  canPromote = true;

  limitedPlaces = false;

  CommentModeration = CommentModeration;

  showFixedNavbar = true;

  observer!: IntersectionObserver;

  dateSettingsIsOpen = false;

  endsOnNull = false;

  @Watch("eventId", { immediate: true })
  resetFormForCreation(eventId: string) {
    if (eventId === undefined) {
      this.event = new EventModel();
    }
  }

  private initializeEvent() {
    // TODO : Check me
    // const roundUpTo = (roundTo) => (x: number) => new Date(Math.ceil(x / roundTo) * roundTo);
    // const roundUpTo15Minutes = roundUpTo(1000 * 60 * 15);

    // const now = roundUpTo15Minutes(new Date());
    // const end = roundUpTo15Minutes(new Date());
    const now = new Date();
    const end = new Date();
    end.setUTCHours(now.getUTCHours() + 3);

    this.event.beginsOn = now;
    this.event.endsOn = end;
    this.event.organizerActor = this.event.organizerActor || this.currentActor;
  }

  async mounted() {
    this.observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry) {
            this.showFixedNavbar = !entry.isIntersecting;
          }
        }
      },
      {
        rootMargin: "-50px 0px -50px",
      }
    );
    this.observer.observe(this.$refs.bottomObserver as Element);

    this.pictureFile = await buildFileFromIPicture(this.event.picture);
    this.limitedPlaces = this.event.options.maximumAttendeeCapacity > 0;
    if (!(this.isUpdate || this.isDuplicate)) {
      this.initializeEvent();
    }
  }

  createOrUpdateDraft(e: Event) {
    e.preventDefault();
    if (this.validateForm()) {
      if (this.eventId && !this.isDuplicate) return this.updateEvent();

      return this.createEvent();
    }
  }

  createOrUpdatePublish(e: Event) {
    if (this.validateForm()) {
      this.event.draft = false;
      this.createOrUpdateDraft(e);
    }
  }

  @Watch("currentActor")
  setCurrentActor() {
    this.event.organizerActor = this.currentActor;
  }

  @Watch("event")
  setInitialData() {
    if (this.isUpdate && this.unmodifiedEvent === undefined && this.event && this.event.uuid) {
      this.unmodifiedEvent = JSON.parse(JSON.stringify(this.event.toEditJSON()));
    }
  }

  resetAttributedToOnOrganizerChange() {
    this.event.attributedTo = new Group();
  }

  // @Watch('event.attributedTo', { deep: true })
  // updateHideOrganizerWhenGroupEventOption(attributedTo) {
  //   if (!attributedTo.preferredUsername) {
  //     this.event.options.hideOrganizerWhenGroupEvent = false;
  //   }
  // }

  private validateForm() {
    const form = this.$refs.form as HTMLFormElement;
    if (form.checkValidity()) {
      return true;
    }
    form.reportValidity();
    return false;
  }

  async createEvent() {
    const variables = await this.buildVariables();

    try {
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_EVENT,
        variables,
        update: (store, { data: { createEvent } }) => this.postCreateOrUpdate(store, createEvent),
        refetchQueries: ({ data: { createEvent } }) => this.postRefetchQueries(createEvent),
      });

      this.$buefy.notification.open({
        message: (this.event.draft
          ? this.$i18n.t("The event has been created as a draft")
          : this.$i18n.t("The event has been published")) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
      await this.$router.push({
        name: "Event",
        params: { uuid: data.createEvent.uuid },
      });
    } catch (err) {
      console.error(err);
    }
  }

  async updateEvent() {
    const variables = await this.buildVariables();

    try {
      await this.$apollo.mutate({
        mutation: EDIT_EVENT,
        variables,
        update: (store, { data: { updateEvent } }) => this.postCreateOrUpdate(store, updateEvent),
        refetchQueries: ({ data: { updateEvent } }) => this.postRefetchQueries(updateEvent),
      });

      this.$buefy.notification.open({
        message: this.updateEventMessage,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
      await this.$router.push({
        name: "Event",
        params: { uuid: this.eventId as string },
      });
    } catch (err) {
      console.error(err);
    }
  }

  get updateEventMessage(): string {
    if (this.unmodifiedEvent.draft && !this.event.draft)
      return this.$i18n.t("The event has been updated and published") as string;
    return (this.event.draft
      ? this.$i18n.t("The draft event has been updated")
      : this.$i18n.t("The event has been updated")) as string;
  }

  /**
   * Put in cache the updated or created event.
   * If the event is not a draft anymore, also put in cache the participation
   */
  private postCreateOrUpdate(store: any, updateEvent: IEvent) {
    const resultEvent: IEvent = { ...updateEvent };
    const organizerActor: IPerson = this.event.organizerActor as Person;
    resultEvent.organizerActor = organizerActor;
    resultEvent.relatedEvents = [];

    store.writeQuery({
      query: FETCH_EVENT,
      variables: { uuid: updateEvent.uuid },
      data: { event: resultEvent },
    });
    if (!updateEvent.draft) {
      store.writeQuery({
        query: EVENT_PERSON_PARTICIPATION,
        variables: {
          eventId: updateEvent.id,
          name: organizerActor.preferredUsername,
        },
        data: {
          person: {
            __typename: "Person",
            id: organizerActor.id,
            participations: {
              total: 1,
              elements: [
                {
                  __typename: "Participant",
                  id: "unknown",
                  role: ParticipantRole.CREATOR,
                  actor: {
                    __typename: "Actor",
                    id: organizerActor.id,
                  },
                  event: {
                    __typename: "Event",
                    id: updateEvent.id,
                  },
                },
              ],
            },
          },
        },
      });
    }
  }

  /**
   * Refresh drafts or participation cache depending if the event is still draft or not
   */
  private postRefetchQueries(updateEvent: IEvent) {
    if (updateEvent.draft) {
      return [
        {
          query: LOGGED_USER_DRAFTS,
        },
      ];
    }
    return [
      {
        query: LOGGED_USER_PARTICIPATIONS,
        variables: {
          afterDateTime: new Date(),
        },
      },
    ];
  }

  /**
   * Build variables for Event GraphQL creation query
   */
  private async buildVariables() {
    let res = this.event.toEditJSON();
    if (this.event.organizerActor) {
      res = Object.assign(res, {
        organizerActorId: this.event.organizerActor.id,
      });
    }
    if (this.event.attributedTo) {
      res = Object.assign(res, { attributedToId: this.event.attributedTo.id });
    }

    // eslint-disable-next-line
    // @ts-ignore
    delete this.event.options.__typename;

    if (this.event.physicalAddress) {
      // eslint-disable-next-line
      // @ts-ignore
      delete this.event.physicalAddress.__typename;
    }

    if (this.endsOnNull) {
      res.endsOn = null;
    }

    const pictureObj = buildFileVariable(this.pictureFile, "picture");
    res = { ...res, ...pictureObj };

    try {
      if (this.event.picture) {
        const oldPictureFile = (await buildFileFromIPicture(this.event.picture)) as File;
        const oldPictureFileContent = await readFileAsync(oldPictureFile);
        const newPictureFileContent = await readFileAsync(this.pictureFile as File);
        if (oldPictureFileContent === newPictureFileContent) {
          res.picture = { pictureId: this.event.picture.id };
        }
      }
    } catch (e) {
      console.error(e);
    }
    return res;
  }

  private async getEvent() {
    const result = await this.$apollo.query({
      query: FETCH_EVENT,
      variables: {
        uuid: this.eventId,
      },
    });

    if (result.data.event.endsOn === null) {
      this.endsOnNull = true;
    }
    // as stated here : https://github.com/elixir-ecto/ecto/issues/1684
    // "Ecto currently silently transforms empty strings into nil"
    if (result.data.event.description === null) {
      result.data.event.description = "";
    }
    return new EventModel(result.data.event);
  }

  @Watch("limitedPlaces")
  updatedEventCapacityOptions(limitedPlaces: boolean) {
    if (!limitedPlaces) {
      this.event.options.maximumAttendeeCapacity = 0;
      this.event.options.remainingAttendeeCapacity = 0;
      this.event.options.showRemainingAttendeeCapacity = false;
    } else {
      this.event.options.maximumAttendeeCapacity =
        this.event.options.maximumAttendeeCapacity || DEFAULT_LIMIT_NUMBER_OF_PLACES;
    }
  }

  @Watch("needsApproval")
  updateEventJoinOptions(needsApproval: boolean) {
    if (needsApproval === true) {
      this.event.joinOptions = EventJoinOptions.RESTRICTED;
    } else {
      this.event.joinOptions = EventJoinOptions.FREE;
    }
  }

  get checkTitleLength() {
    return this.event.title.length > 80
      ? ["is-info", this.$t("The event title will be ellipsed.")]
      : [undefined, undefined];
  }

  /**
   * Confirm cancel
   */
  confirmGoElsewhere(callback: (value?: string) => any) {
    if (!this.isEventModified) {
      return callback();
    }
    const title: string = this.isUpdate
      ? (this.$t("Cancel edition") as string)
      : (this.$t("Cancel creation") as string);
    const message: string = this.isUpdate
      ? (this.$t(
          "Are you sure you want to cancel the event edition? You'll lose all modifications.",
          { title: this.event.title }
        ) as string)
      : (this.$t(
          "Are you sure you want to cancel the event creation? You'll lose all modifications.",
          { title: this.event.title }
        ) as string);

    this.$buefy.dialog.confirm({
      title,
      message,
      confirmText: this.$t("Abandon edition") as string,
      cancelText: this.$t("Continue editing") as string,
      type: "is-warning",
      hasIcon: true,
      onConfirm: callback,
    });
  }

  /**
   * Confirm cancel
   */
  confirmGoBack() {
    this.confirmGoElsewhere(() => this.$router.go(-1));
  }

  beforeRouteLeave(to: Route, from: Route, next: Function) {
    if (to.name === RouteName.EVENT) return next();
    this.confirmGoElsewhere(() => next());
  }

  get isEventModified(): boolean {
    return JSON.stringify(this.event.toEditJSON()) !== JSON.stringify(this.unmodifiedEvent);
  }

  get beginsOn(): Date {
    return this.event.beginsOn;
  }

  @Watch("beginsOn", { deep: true })
  onBeginsOnChanged(beginsOn: string) {
    if (!this.event.endsOn) return;
    const dateBeginsOn = new Date(beginsOn);
    const dateEndsOn = new Date(this.event.endsOn);
    if (dateEndsOn < dateBeginsOn) {
      this.event.endsOn = dateBeginsOn;
      this.event.endsOn.setHours(dateBeginsOn.getHours() + 1);
    }
    if (dateEndsOn === dateBeginsOn) {
      this.event.endsOn.setHours(dateEndsOn.getHours() + 1);
    }
  }

  /**
   * In event endsOn datepicker, we lock starting with the day before the beginsOn date
   */
  get minDateForEndsOn(): Date {
    const minDate = new Date(this.event.beginsOn);
    minDate.setDate(minDate.getDate() - 1);
    return minDate;
  }
}
</script>
