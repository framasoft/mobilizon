<template>
  <section>
    <div class="container" v-if="isCurrentActorOrganizer">
      <h1 class="title" v-if="isUpdate === true">
        {{ $t("Update event {name}", { name: event.title }) }}
      </h1>
      <h1 class="title" v-else>
        {{ $t("Create a new event") }}
      </h1>

      <form ref="form">
        <subtitle>{{ $t("General information") }}</subtitle>
        <picture-upload
          v-model="pictureFile"
          :textFallback="$t('Headline picture')"
          :defaultImage="event.picture"
        />

        <b-field
          :label="$t('Title')"
          :type="checkTitleLength[0]"
          :message="checkTitleLength[1]"
        >
          <b-input
            size="is-large"
            aria-required="true"
            required
            v-model="event.title"
          />
        </b-field>

        <tag-input v-model="event.tags" :data="tags" path="title" />

        <b-field horizontal :label="$t('Starts on…')" class="begins-on-field">
          <b-datetimepicker
            class="datepicker starts-on"
            :placeholder="$t('Type or select a date…')"
            icon="calendar-today"
            :locale="$i18n.locale"
            v-model="event.beginsOn"
            horizontal-time-picker
            editable
          >
          </b-datetimepicker>
        </b-field>

        <b-field horizontal :label="$t('Ends on…')">
          <b-datetimepicker
            class="datepicker ends-on"
            :placeholder="$t('Type or select a date…')"
            icon="calendar-today"
            :locale="$i18n.locale"
            v-model="event.endsOn"
            horizontal-time-picker
            :min-datetime="event.beginsOn"
            editable
          >
          </b-datetimepicker>
        </b-field>

        <!--          <b-switch v-model="endsOnNull">{{ $t('No end date') }}</b-switch>-->
        <b-button type="is-text" @click="dateSettingsIsOpen = true">
          {{ $t("Date parameters") }}
        </b-button>

        <full-address-auto-complete v-model="event.physicalAddress" />

        <div class="field">
          <label class="label">{{ $t("Description") }}</label>
          <editor v-model="event.description" />
        </div>

        <b-field :label="$t('Website / URL')">
          <b-input
            icon="link"
            type="url"
            v-model="event.onlineAddress"
            placeholder="URL"
          />
        </b-field>

        <subtitle>{{ $t("Organizers") }}</subtitle>

        <div v-if="config && config.features.groups">
          <b-field>
            <organizer-picker-wrapper
              v-model="event.attributedTo"
              :contacts.sync="event.contacts"
              :identity="event.organizerActor"
            />
          </b-field>
          <p v-if="!event.attributedTo.id || attributedToEqualToOrganizerActor">
            {{
              $t("The event will show as attributed to your personal profile.")
            }}
          </p>
          <p v-else>
            <span>{{
              $t("The event will show as attributed to this group.")
            }}</span>
            <span
              v-if="event.contacts && event.contacts.length"
              v-html="
                $tc(
                  '<b>{contact}</b> will be displayed as contact.',
                  event.contacts.length,
                  {
                    contact: formatList(
                      event.contacts.map((contact) =>
                        displayNameAndUsername(contact)
                      )
                    ),
                  }
                )
              "
            />
          </p>
        </div>
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
            >{{ $t("Only accessible through link (private)") }}</b-radio
          >
        </div>
        <!-- <div class="field">
          <b-radio v-model="event.visibility"
                   name="eventVisibility"
                   :native-value="EventVisibility.PRIVATE">
             {{ $t('Page limited to my group (asks for auth)') }}
          </b-radio>
        </div>-->

        <div
          class="field"
          v-if="config && config.anonymous.participation.allowed"
        >
          <label class="label">{{ $t("Anonymous participations") }}</label>
          <b-switch v-model="event.options.anonymousParticipation">
            {{
              $t("I want to allow people to participate without an account.")
            }}
            <small
              v-if="
                config.anonymous.participation.validation.email
                  .confirmationRequired
              "
            >
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
          <b-switch v-model="limitedPlaces">{{
            $t("Limited number of places")
          }}</b-switch>
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
            >{{ $t("Allow all comments from users with accounts") }}</b-radio
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

        <b-field class="event__status__field">
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
    <b-modal v-model="dateSettingsIsOpen" has-modal-card trap-focus>
      <form action>
        <div class="modal-card" style="width: auto">
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
            <button
              class="button"
              type="button"
              @click="dateSettingsIsOpen = false"
            >
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
      class="navbar save__navbar"
      :class="{ 'is-fixed-bottom': showFixedNavbar }"
      v-if="isCurrentActorOrganizer"
    >
      <div class="container">
        <div class="navbar-menu">
          <div class="navbar-start">
            <span class="navbar-item" v-if="isEventModified">{{
              $t("Unsaved changes")
            }}</span>
          </div>
          <div class="navbar-end">
            <span class="navbar-item">
              <b-button type="is-text" @click="confirmGoBack">{{
                $t("Cancel")
              }}</b-button>
            </span>
            <!-- If an event has been published we can't make it draft anymore -->
            <span class="navbar-item" v-if="event.draft === true">
              <b-button
                type="is-primary"
                outlined
                @click="createOrUpdateDraft"
                :disabled="saving"
                >{{ $t("Save draft") }}</b-button
              >
            </span>
            <span class="navbar-item">
              <b-button
                type="is-primary"
                :disabled="saving"
                @click="createOrUpdatePublish"
                @keyup.enter="createOrUpdatePublish"
              >
                <span v-if="isUpdate === false">{{
                  $t("Create my event")
                }}</span>
                <span v-else-if="event.draft === true">{{
                  $t("Publish")
                }}</span>
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
main section > .container {
  background: $white;
}

.save__navbar {
  ::v-deep .navbar-menu,
  .navbar-end {
    flex-wrap: wrap;
  }
}

@media screen and (max-width: 768px) {
  .navbar.is-fixed-bottom {
    position: initial;
  }
}

h2.subtitle {
  margin: 10px 0;

  span {
    padding: 5px 7px;
    display: inline;
    background: $secondary;
  }
}

.event__status__field {
  ::v-deep .field.has-addons {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-start;
  }
}

.datepicker {
  ::v-deep .dropdown-menu {
    z-index: 200;
  }
}

section {
  & > .container {
    padding: 2rem 1.5rem;
  }

  .begins-on-field {
    margin-top: 22px;
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
import { RefetchQueryDescription } from "apollo-client/core/watchQueryOptions";
import PictureUpload from "@/components/PictureUpload.vue";
import EditorComponent from "@/components/Editor.vue";
import TagInput from "@/components/Event/TagInput.vue";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";
import IdentityPickerWrapper from "@/views/Account/IdentityPickerWrapper.vue";
import Subtitle from "@/components/Utils/Subtitle.vue";
import { Route } from "vue-router";
import { formatList } from "@/utils/i18n";
import {
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  ParticipantRole,
} from "@/types/enums";
import OrganizerPickerWrapper from "../../components/Event/OrganizerPickerWrapper.vue";
import {
  CREATE_EVENT,
  EDIT_EVENT,
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
} from "../../graphql/event";
import { EventModel, IEvent } from "../../types/event.model";
import {
  CURRENT_ACTOR_CLIENT,
  LOGGED_USER_DRAFTS,
  LOGGED_USER_PARTICIPATIONS,
} from "../../graphql/actor";
import { IPerson, Person, displayNameAndUsername } from "../../types/actor";
import { TAGS } from "../../graphql/tags";
import { ITag } from "../../types/tag.model";
import {
  buildFileFromIMedia,
  buildFileVariable,
  readFileAsync,
} from "../../utils/image";
import RouteName from "../../router/name";
import "intersection-observer";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";

const DEFAULT_LIMIT_NUMBER_OF_PLACES = 10;

@Component({
  components: {
    OrganizerPickerWrapper,
    Subtitle,
    IdentityPickerWrapper,
    FullAddressAutoComplete,
    TagInput,
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
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: (this.isUpdate
        ? this.$t("Event edition")
        : this.$t("Event creation")) as string,
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

  saving = false;

  displayNameAndUsername = displayNameAndUsername;

  formatList = formatList;

  @Watch("eventId", { immediate: true })
  resetFormForCreation(eventId: string): void {
    if (eventId === undefined) {
      this.event = new EventModel();
    }
  }

  private initializeEvent() {
    const roundUpTo15Minutes = (time: Date) => {
      time.setMilliseconds(Math.round(time.getMilliseconds() / 1000) * 1000);
      time.setSeconds(Math.round(time.getSeconds() / 60) * 60);
      time.setMinutes(Math.round(time.getMinutes() / 15) * 15);
      return time;
    };

    const now = roundUpTo15Minutes(new Date());
    const end = new Date(now.valueOf());

    end.setUTCHours(now.getUTCHours() + 3);

    this.event.beginsOn = now;
    this.event.endsOn = end;
    this.event.organizerActor = this.getDefaultActor();
  }

  private getDefaultActor() {
    if (this.event.organizerActor?.id) {
      return this.event.organizerActor;
    }
    return this.currentActor;
  }

  async mounted(): Promise<void> {
    this.observer = new IntersectionObserver(
      (entries) => {
        // eslint-disable-next-line no-restricted-syntax
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

    this.pictureFile = await buildFileFromIMedia(this.event.picture);
    this.limitedPlaces = this.event.options.maximumAttendeeCapacity > 0;
    if (!(this.isUpdate || this.isDuplicate)) {
      this.initializeEvent();
    } else {
      this.event.description = this.event.description || "";
    }
  }

  createOrUpdateDraft(e: Event): void {
    e.preventDefault();
    if (this.validateForm()) {
      if (this.eventId && !this.isDuplicate) {
        this.updateEvent();
      } else {
        this.createEvent();
      }
    }
  }

  createOrUpdatePublish(e: Event): void {
    e.preventDefault();
    if (this.validateForm()) {
      this.event.draft = false;
      this.createOrUpdateDraft(e);
    }
  }

  @Watch("event")
  setInitialData(): void {
    if (
      this.isUpdate &&
      this.unmodifiedEvent === undefined &&
      this.event &&
      this.event.uuid
    ) {
      this.unmodifiedEvent = JSON.parse(
        JSON.stringify(this.event.toEditJSON())
      );
    }
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

  async createEvent(): Promise<void> {
    this.saving = true;
    const variables = await this.buildVariables();

    try {
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_EVENT,
        variables,
        update: (store, { data: { createEvent } }) =>
          this.postCreateOrUpdate(store, createEvent),
        refetchQueries: ({ data: { createEvent } }) =>
          this.postRefetchQueries(createEvent),
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
      this.saving = false;
      console.error(err);
      this.handleError(err);
    }
  }

  async updateEvent(): Promise<void> {
    this.saving = true;
    const variables = await this.buildVariables();

    try {
      await this.$apollo.mutate({
        mutation: EDIT_EVENT,
        variables,
        update: (store, { data: { updateEvent } }) =>
          this.postCreateOrUpdate(store, updateEvent),
        refetchQueries: ({ data: { updateEvent } }) =>
          this.postRefetchQueries(updateEvent),
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
      this.saving = false;
      this.handleError(err);
    }
  }

  get isCurrentActorOrganizer(): boolean {
    return !(
      this.eventId &&
      this.event.organizerActor?.id !== undefined &&
      this.currentActor.id !== this.event.organizerActor.id
    ) as boolean;
  }

  get updateEventMessage(): string {
    if (this.unmodifiedEvent.draft && !this.event.draft)
      return this.$i18n.t("The event has been updated and published") as string;
    return (this.event.draft
      ? this.$i18n.t("The draft event has been updated")
      : this.$i18n.t("The event has been updated")) as string;
  }

  private handleError(err: any) {
    console.error(err);

    if (err.graphQLErrors !== undefined) {
      err.graphQLErrors.forEach(({ message }: { message: string }) => {
        this.$notifier.error(message);
      });
    }
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
              __typename: "PaginatedParticipantList",
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
  // eslint-disable-next-line class-methods-use-this
  private postRefetchQueries(updateEvent: IEvent): RefetchQueryDescription {
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

  get attributedToEqualToOrganizerActor(): boolean {
    return (this.event.organizerActor?.id !== undefined &&
      this.event.attributedTo?.id === this.event.organizerActor?.id) as boolean;
  }

  /**
   * Build variables for Event GraphQL creation query
   */
  private async buildVariables() {
    this.event.organizerActor = this.event.organizerActor?.id
      ? this.event.organizerActor
      : this.currentActor;
    let res = this.event.toEditJSON();
    if (this.event.organizerActor) {
      res = Object.assign(res, {
        organizerActorId: this.event.organizerActor.id,
      });
    }
    const attributedToId =
      this.event.attributedTo &&
      !this.attributedToEqualToOrganizerActor &&
      this.event.attributedTo.id
        ? this.event.attributedTo.id
        : null;
    res = Object.assign(res, { attributedToId });

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

    if (this.pictureFile) {
      const pictureObj = buildFileVariable(this.pictureFile, "picture");
      res = { ...res, ...pictureObj };
    }

    try {
      if (this.event.picture && this.pictureFile) {
        const oldPictureFile = (await buildFileFromIMedia(
          this.event.picture
        )) as File;
        const oldPictureFileContent = await readFileAsync(oldPictureFile);
        const newPictureFileContent = await readFileAsync(
          this.pictureFile as File
        );
        if (oldPictureFileContent === newPictureFileContent) {
          res.picture = { mediaId: this.event.picture.id };
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
  updatedEventCapacityOptions(limitedPlaces: boolean): void {
    if (!limitedPlaces) {
      this.event.options.maximumAttendeeCapacity = 0;
      this.event.options.remainingAttendeeCapacity = 0;
      this.event.options.showRemainingAttendeeCapacity = false;
    } else {
      this.event.options.maximumAttendeeCapacity =
        this.event.options.maximumAttendeeCapacity ||
        DEFAULT_LIMIT_NUMBER_OF_PLACES;
    }
  }

  @Watch("needsApproval")
  updateEventJoinOptions(needsApproval: boolean): void {
    if (needsApproval === true) {
      this.event.joinOptions = EventJoinOptions.RESTRICTED;
    } else {
      this.event.joinOptions = EventJoinOptions.FREE;
    }
  }

  get checkTitleLength(): Array<string | undefined> {
    return this.event.title.length > 80
      ? ["is-info", this.$t("The event title will be ellipsed.") as string]
      : [undefined, undefined];
  }

  /**
   * Confirm cancel
   */
  confirmGoElsewhere(callback: () => any): void {
    if (!this.isEventModified) {
      callback();
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
      confirmText: this.$t("Abandon editing") as string,
      cancelText: this.$t("Continue editing") as string,
      type: "is-warning",
      hasIcon: true,
      onConfirm: callback,
    });
  }

  /**
   * Confirm cancel
   */
  confirmGoBack(): void {
    this.confirmGoElsewhere(() => this.$router.go(-1));
  }

  // eslint-disable-next-line consistent-return
  beforeRouteLeave(to: Route, from: Route, next: () => void): void {
    if (to.name === RouteName.EVENT) return next();
    this.confirmGoElsewhere(() => next());
  }

  get isEventModified(): boolean {
    return (
      JSON.stringify(this.event.toEditJSON()) !==
      JSON.stringify(this.unmodifiedEvent)
    );
  }

  get beginsOn(): Date {
    return this.event.beginsOn;
  }

  @Watch("beginsOn", { deep: true })
  onBeginsOnChanged(beginsOn: string): void {
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
