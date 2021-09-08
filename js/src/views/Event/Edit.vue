<template>
  <section>
    <div class="container" v-if="hasCurrentActorPermissionsToEdit">
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
          label-for="title"
          :type="checkTitleLength[0]"
          :message="checkTitleLength[1]"
        >
          <b-input
            size="is-large"
            aria-required="true"
            required
            v-model="event.title"
            id="title"
          />
        </b-field>

        <tag-input v-model="event.tags" :data="tags" path="title" />

        <b-field
          horizontal
          :label="$t('Starts on…')"
          class="begins-on-field"
          label-for="begins-on-field"
        >
          <b-datetimepicker
            class="datepicker starts-on"
            :placeholder="$t('Type or select a date…')"
            icon="calendar-today"
            :locale="$i18n.locale"
            v-model="event.beginsOn"
            horizontal-time-picker
            editable
            :datepicker="{
              id: 'begins-on-field',
              'aria-next-label': $t('Next month'),
              'aria-previous-label': $t('Previous month'),
            }"
          >
          </b-datetimepicker>
        </b-field>

        <b-field horizontal :label="$t('Ends on…')" label-for="ends-on-field">
          <b-datetimepicker
            class="datepicker ends-on"
            :placeholder="$t('Type or select a date…')"
            icon="calendar-today"
            :locale="$i18n.locale"
            v-model="event.endsOn"
            horizontal-time-picker
            :min-datetime="event.beginsOn"
            editable
            :datepicker="{
              id: 'ends-on-field',
              'aria-next-label': $t('Next month'),
              'aria-previous-label': $t('Previous month'),
            }"
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

        <b-field :label="$t('Website / URL')" label-for="website-url">
          <b-input
            icon="link"
            type="url"
            v-model="event.onlineAddress"
            placeholder="URL"
            id="website-url"
          />
        </b-field>

        <subtitle>{{ $t("Organizers") }}</subtitle>

        <div v-if="config && config.features.groups && organizerActor.id">
          <b-field>
            <organizer-picker-wrapper
              v-model="organizerActor"
              :contacts.sync="event.contacts"
            />
          </b-field>
          <p v-if="!attributedToAGroup && organizerActorEqualToCurrentActor">
            {{
              $t("The event will show as attributed to your personal profile.")
            }}
          </p>
          <p v-else-if="!attributedToAGroup">
            {{ $t("The event will show as attributed to this profile.") }}
          </p>
          <p v-else>
            <span>{{
              $t("The event will show as attributed to this group.")
            }}</span>
            <span
              v-if="event.contacts && event.contacts.length"
              v-html="
                ' ' +
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
            <span v-else>
              {{ $t("You may show some members as contacts.") }}
            </span>
          </p>
        </div>
        <subtitle>{{ $t("Event metadata") }}</subtitle>
        <p>
          {{
            $t(
              "Integrate this event with 3rd-party tools and show metadata for the event."
            )
          }}
        </p>
        <event-metadata-list v-model="event.metadata" />
        <subtitle>{{ $t("Who can view this event and participate") }}</subtitle>
        <fieldset>
          <legend>
            {{
              $t(
                "When the event is private, you'll need to share the link around."
              )
            }}
          </legend>
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
        </fieldset>
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
          <b-switch v-model="eventOptions.anonymousParticipation">
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
          <b-field :label="$t('Number of places')" label-for="number-of-places">
            <b-numberinput
              controls-position="compact"
              :aria-minus-label="$t('Decrease')"
              :aria-plus-label="$t('Increase')"
              min="1"
              v-model="eventOptions.maximumAttendeeCapacity"
              id="number-of-places"
            />
          </b-field>
          <!--
          <b-field>
            <b-switch v-model="eventOptions.showRemainingAttendeeCapacity">
              {{ $t('Show remaining number of places') }}
            </b-switch>
          </b-field>

          <b-field>
            <b-switch v-model="eventOptions.showParticipationPrice">
              {{ $t('Display participation price') }}
            </b-switch>
          </b-field>-->
        </div>

        <subtitle>{{ $t("Public comment moderation") }}</subtitle>

        <fieldset>
          <legend>{{ $t("Who can post a comment?") }}</legend>
          <div class="field">
            <b-radio
              v-model="eventOptions.commentModeration"
              name="commentModeration"
              :native-value="CommentModeration.ALLOW_ALL"
              >{{ $t("Allow all comments from users with accounts") }}</b-radio
            >
          </div>

          <!--          <div class="field">-->
          <!--            <b-radio v-model="eventOptions.commentModeration"-->
          <!--                     name="commentModeration"-->
          <!--                     :native-value="CommentModeration.MODERATED">-->
          <!--              {{ $t('Moderated comments (shown after approval)') }}-->
          <!--            </b-radio>-->
          <!--          </div>-->

          <div class="field">
            <b-radio
              v-model="eventOptions.commentModeration"
              name="commentModeration"
              :native-value="CommentModeration.CLOSED"
              >{{ $t("Close comments for all (except for admins)") }}</b-radio
            >
          </div>
        </fieldset>

        <subtitle>{{ $t("Status") }}</subtitle>

        <fieldset>
          <legend>
            {{
              $t(
                "Does the event needs to be confirmed later or is it cancelled?"
              )
            }}
          </legend>
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
        </fieldset>
      </form>
    </div>
    <div class="container section" v-else>
      <b-message type="is-danger">
        {{ $t("Only group moderators can create, edit and delete events.") }}
      </b-message>
    </div>
    <b-modal v-model="dateSettingsIsOpen" has-modal-card trap-focus>
      <form action>
        <div class="modal-card" style="width: auto">
          <header class="modal-card-head">
            <p class="modal-card-title">{{ $t("Date and time settings") }}</p>
          </header>
          <section class="modal-card-body">
            <b-field :label="$t('Event page settings')">
              <b-switch v-model="eventOptions.showStartTime">{{
                $t("Show the time when the event begins")
              }}</b-switch>
            </b-field>
            <b-field>
              <b-switch v-model="eventOptions.showEndTime">{{
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
      v-if="hasCurrentActorPermissionsToEdit"
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

  form {
    h2 {
      margin: 15px 0 7.5px;
    }

    legend {
      margin-bottom: 0.75rem;
    }
  }
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
    @media screen and (max-width: 768px) {
      padding: 2rem 0.5rem;
    }
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
<style lang="scss">
.dialog .modal-card {
  max-width: 500px;

  .modal-card-foot {
    justify-content: center;
    flex-wrap: wrap;

    & > button {
      margin-bottom: 5px;
    }
  }
}
</style>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import PictureUpload from "@/components/PictureUpload.vue";
import EditorComponent from "@/components/Editor.vue";
import TagInput from "@/components/Event/TagInput.vue";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";
import EventMetadataList from "@/components/Event/EventMetadataList.vue";
import IdentityPickerWrapper from "@/views/Account/IdentityPickerWrapper.vue";
import Subtitle from "@/components/Utils/Subtitle.vue";
import { RawLocation, Route } from "vue-router";
import { formatList } from "@/utils/i18n";
import {
  ActorType,
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  MemberRole,
  ParticipantRole,
} from "@/types/enums";
import OrganizerPickerWrapper from "../../components/Event/OrganizerPickerWrapper.vue";
import {
  CREATE_EVENT,
  EDIT_EVENT,
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
} from "../../graphql/event";
import {
  EventModel,
  IEvent,
  removeTypeName,
  toEditJSON,
} from "../../types/event.model";
import {
  CURRENT_ACTOR_CLIENT,
  IDENTITIES,
  LOGGED_USER_DRAFTS,
  LOGGED_USER_PARTICIPATIONS,
  PERSON_MEMBERSHIP_GROUP,
} from "../../graphql/actor";
import {
  displayNameAndUsername,
  IActor,
  IGroup,
  IPerson,
  usernameWithDomain,
} from "../../types/actor";
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
import {
  ApolloCache,
  FetchResult,
  InternalRefetchQueriesInclude,
} from "@apollo/client/core";
import cloneDeep from "lodash/cloneDeep";
import { IEventOptions } from "@/types/event-options.model";

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
    EventMetadataList,
  },
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    tags: TAGS,
    config: CONFIG,
    identities: IDENTITIES,
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
    person: {
      query: PERSON_MEMBERSHIP_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
          group: usernameWithDomain(this.event?.attributedTo),
        };
      },
      skip() {
        return (
          !this.event?.attributedTo ||
          !this.event?.attributedTo?.preferredUsername
        );
      },
    },
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: (this.isUpdate
        ? this.$t("Event edition")
        : this.$t("Event creation")) as string,
    };
  },
})
export default class EditEvent extends Vue {
  @Prop({ required: false, type: String }) eventId: undefined | string;

  @Prop({ type: Boolean, default: false }) isUpdate!: boolean;

  @Prop({ type: Boolean, default: false }) isDuplicate!: boolean;

  currentActor!: IActor;

  tags: ITag[] = [];

  event: IEvent = new EventModel();

  unmodifiedEvent: IEvent = new EventModel();

  identities: IActor[] = [];

  person!: IPerson;

  config!: IConfig;

  pictureFile: File | null = null;

  EventStatus = EventStatus;

  EventVisibility = EventVisibility;

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
  }

  get organizerActor(): IActor {
    if (this.event?.attributedTo?.id) {
      return this.event.attributedTo;
    }
    if (this.event?.organizerActor?.id) {
      return this.event.organizerActor;
    }
    return this.currentActor;
  }

  set organizerActor(actor: IActor) {
    if (actor?.type === ActorType.GROUP) {
      this.event.attributedTo = actor as IGroup;
      this.event.organizerActor = this.currentActor;
    } else {
      this.event.attributedTo = undefined;
      this.event.organizerActor = actor;
    }
  }

  get attributedToAGroup(): boolean {
    return this.event.attributedTo?.id !== undefined;
  }

  get eventOptions(): IEventOptions {
    return removeTypeName(cloneDeep(this.event.options));
  }

  set eventOptions(options: IEventOptions) {
    this.event.options = options;
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
    this.limitedPlaces = this.eventOptions.maximumAttendeeCapacity > 0;
    if (!(this.isUpdate || this.isDuplicate)) {
      this.initializeEvent();
    } else {
      this.event = new EventModel({
        ...this.event,
        options: cloneDeep(this.event.options),
        description: this.event.description || "",
      });
    }
    this.unmodifiedEvent = cloneDeep(this.event);
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
      const { data } = await this.$apollo.mutate<{ createEvent: IEvent }>({
        mutation: CREATE_EVENT,
        variables,
        update: (
          store: ApolloCache<{ createEvent: IEvent }>,
          { data: updatedData }: FetchResult
        ) => this.postCreateOrUpdate(store, updatedData?.createEvent),
        refetchQueries: ({ data: updatedData }: FetchResult) =>
          this.postRefetchQueries(updatedData?.createEvent),
      });

      this.$buefy.notification.open({
        message: (this.event.draft
          ? this.$i18n.t("The event has been created as a draft")
          : this.$i18n.t("The event has been published")) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
      if (data?.createEvent) {
        await this.$router.push({
          name: "Event",
          params: { uuid: data.createEvent.uuid },
        });
      }
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
      await this.$apollo.mutate<{ updateEvent: IEvent }>({
        mutation: EDIT_EVENT,
        variables,
        update: (
          store: ApolloCache<{ updateEvent: IEvent }>,
          { data: updatedData }: FetchResult
        ) => this.postCreateOrUpdate(store, updatedData?.updateEvent),
        refetchQueries: ({ data }: FetchResult) =>
          this.postRefetchQueries(data?.updateEvent),
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

  get hasCurrentActorPermissionsToEdit(): boolean {
    return !(
      this.eventId &&
      this.event.organizerActor?.id !== undefined &&
      !this.identities
        .map(({ id }) => id)
        .includes(this.event.organizerActor?.id) &&
      !this.hasGroupPrivileges
    );
  }

  get hasGroupPrivileges(): boolean {
    return (
      this.person?.memberships?.total > 0 &&
      [MemberRole.MODERATOR, MemberRole.ADMINISTRATOR].includes(
        this.person?.memberships?.elements[0].role
      )
    );
  }

  get updateEventMessage(): string {
    if (this.unmodifiedEvent.draft && !this.event.draft)
      return this.$i18n.t("The event has been updated and published") as string;
    return (
      this.event.draft
        ? this.$i18n.t("The draft event has been updated")
        : this.$i18n.t("The event has been updated")
    ) as string;
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
    console.log(resultEvent);
    if (!updateEvent.draft) {
      store.writeQuery({
        query: EVENT_PERSON_PARTICIPATION,
        variables: {
          eventId: resultEvent.id,
          name: resultEvent.organizerActor?.preferredUsername,
        },
        data: {
          person: {
            __typename: "Person",
            id: resultEvent?.organizerActor?.id,
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
                    id: resultEvent?.organizerActor?.id,
                  },
                  event: {
                    __typename: "Event",
                    id: resultEvent.id,
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
  private postRefetchQueries(
    updateEvent: IEvent
  ): InternalRefetchQueriesInclude {
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

  get organizerActorEqualToCurrentActor(): boolean {
    return (
      this.currentActor?.id !== undefined &&
      this.organizerActor?.id === this.currentActor?.id
    );
  }

  /**
   * Build variables for Event GraphQL creation query
   */
  private async buildVariables() {
    let res = {
      ...toEditJSON(new EventModel(this.event)),
      options: this.eventOptions,
    };
    const organizerActor = this.event.organizerActor?.id
      ? this.event.organizerActor
      : this.organizerActor;
    if (organizerActor) {
      res = { ...res, organizerActorId: organizerActor?.id };
    }
    const attributedToId = this.event.attributedTo?.id
      ? this.event.attributedTo.id
      : null;
    res = { ...res, attributedToId };

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

  @Watch("limitedPlaces")
  updatedEventCapacityOptions(limitedPlaces: boolean): void {
    if (!limitedPlaces) {
      this.eventOptions.maximumAttendeeCapacity = 0;
      this.eventOptions.remainingAttendeeCapacity = 0;
      this.eventOptions.showRemainingAttendeeCapacity = false;
    } else {
      this.eventOptions.maximumAttendeeCapacity =
        this.eventOptions.maximumAttendeeCapacity ||
        DEFAULT_LIMIT_NUMBER_OF_PLACES;
    }
  }

  get needsApproval(): boolean {
    return this.event?.joinOptions == EventJoinOptions.RESTRICTED;
  }

  set needsApproval(value: boolean) {
    if (value === true) {
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
  confirmGoElsewhere(): Promise<boolean> {
    // TODO: Make calculation of changes work again and bring this back
    // If the event wasn't modified, no need to warn
    // if (!this.isEventModified) {
    //   return Promise.resolve(true);
    // }
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

    return new Promise((resolve) => {
      this.$buefy.dialog.confirm({
        title,
        message,
        confirmText: this.$t("Abandon editing") as string,
        cancelText: this.$t("Continue editing") as string,
        type: "is-warning",
        hasIcon: true,
        onConfirm: () => resolve(true),
        onCancel: () => resolve(false),
      });
    });
  }

  /**
   * Confirm cancel
   */
  confirmGoBack(): void {
    this.$router.go(-1);
  }

  // eslint-disable-next-line consistent-return
  async beforeRouteLeave(
    to: Route,
    from: Route,
    next: (to?: RawLocation | false | ((vm: any) => void)) => void
  ): Promise<void> {
    if (to.name === RouteName.EVENT) return next();
    if (await this.confirmGoElsewhere()) {
      return next();
    }
    return next(false);
  }

  get isEventModified(): boolean {
    return (
      this.event &&
      this.unmodifiedEvent &&
      JSON.stringify(toEditJSON(this.event)) !==
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
