<template>
  <div class="container mx-auto" v-if="hasCurrentActorPermissionsToEdit">
    <h1 class="" v-if="isUpdate === true">
      {{ t("Update event {name}", { name: event.title }) }}
    </h1>
    <h1 class="" v-else>
      {{ t("Create a new event") }}
    </h1>

    <form ref="form">
      <h2>{{ t("General information") }}</h2>
      <picture-upload
        v-model:modelValue="pictureFile"
        :textFallback="t('Headline picture')"
        :defaultImage="event.picture"
      />

      <o-field
        :label="t('Title')"
        label-for="title"
        :type="checkTitleLength[0]"
        :message="checkTitleLength[1]"
      >
        <o-input
          size="large"
          aria-required="true"
          required
          v-model="event.title"
          id="title"
          dir="auto"
        />
      </o-field>

      <div class="flex flex-wrap gap-4">
        <o-field
          v-if="orderedCategories"
          :label="t('Category')"
          label-for="categoryField"
          class="w-full md:max-w-fit"
        >
          <o-select
            :placeholder="t('Select a category')"
            v-model="event.category"
            id="categoryField"
            expanded
          >
            <option
              v-for="category in orderedCategories"
              :value="category.id"
              :key="category.id"
            >
              {{ category.label }}
            </option>
          </o-select>
        </o-field>
        <tag-input
          v-model="event.tags"
          class="flex-1"
          :fetch-tags="fetchTags"
        />
      </div>

      <o-field
        horizontal
        :label="t('Starts on…')"
        class="begins-on-field"
        label-for="begins-on-field"
      >
        <o-datetimepicker
          class="datepicker starts-on"
          :placeholder="t('Type or select a date…')"
          icon="calendar-today"
          :locale="$i18n.locale.replace('_', '-')"
          v-model="beginsOn"
          horizontal-time-picker
          editable
          :tz-offset="tzOffset(beginsOn)"
          :first-day-of-week="firstDayOfWeek"
          :datepicker="{
            id: 'begins-on-field',
            'aria-next-label': t('Next month'),
            'aria-previous-label': t('Previous month'),
          }"
        >
        </o-datetimepicker>
      </o-field>

      <o-field horizontal :label="t('Ends on…')" label-for="ends-on-field">
        <o-datetimepicker
          class="datepicker ends-on"
          :placeholder="t('Type or select a date…')"
          icon="calendar-today"
          :locale="$i18n.locale.replace('_', '-')"
          v-model="endsOn"
          horizontal-time-picker
          :min-datetime="beginsOn"
          :tz-offset="tzOffset(endsOn)"
          editable
          :first-day-of-week="firstDayOfWeek"
          :datepicker="{
            id: 'ends-on-field',
            'aria-next-label': t('Next month'),
            'aria-previous-label': t('Previous month'),
          }"
        >
        </o-datetimepicker>
      </o-field>

      <o-button class="block" variant="text" @click="dateSettingsIsOpen = true">
        {{ t("Date parameters") }}
      </o-button>

      <div class="my-6">
        <full-address-auto-complete
          v-model="eventPhysicalAddress"
          :user-timezone="userActualTimezone"
          :disabled="event.options.isOnline"
          :hideSelected="true"
        />
        <o-switch class="my-4" v-model="isOnline">{{
          t("The event is fully online")
        }}</o-switch>
      </div>

      <div class="o-field field">
        <label class="o-field__label field-label">{{ t("Description") }}</label>
        <editor-component
          v-if="currentActor"
          :current-actor="(currentActor as IPerson)"
          v-model="event.description"
          :aria-label="t('Event description body')"
          :placeholder="t('Describe your event')"
        />
      </div>

      <o-field :label="t('Website / URL')" label-for="website-url">
        <o-input
          icon="link"
          type="url"
          v-model="event.onlineAddress"
          placeholder="URL"
          id="website-url"
        />
      </o-field>

      <section class="my-4">
        <h2>{{ t("Organizers") }}</h2>

        <div v-if="features?.groups && organizerActor?.id">
          <o-field>
            <organizer-picker-wrapper
              v-model="organizerActor"
              v-model:contacts="event.contacts"
            />
          </o-field>
          <p v-if="!attributedToAGroup && organizerActorEqualToCurrentActor">
            {{
              t("The event will show as attributed to your personal profile.")
            }}
          </p>
          <p v-else-if="!attributedToAGroup">
            {{ t("The event will show as attributed to this profile.") }}
          </p>
          <p v-else>
            <span>{{
              t("The event will show as attributed to this group.")
            }}</span>
            <span
              v-if="event.contacts && event.contacts.length"
              v-html="
                ' ' +
                t(
                  '<b>{contact}</b> will be displayed as contact.',

                  {
                    contact: formatList(
                      event.contacts.map((contact) =>
                        displayNameAndUsername(contact)
                      )
                    ),
                  },
                  event.contacts.length
                )
              "
            />
            <span v-else>
              {{ t("You may show some members as contacts.") }}
            </span>
          </p>
        </div>
      </section>
      <section class="my-4">
        <h2>{{ t("Event metadata") }}</h2>
        <p>
          {{
            t(
              "Integrate this event with 3rd-party tools and show metadata for the event."
            )
          }}
        </p>
        <event-metadata-list v-model="event.metadata" />
      </section>
      <section class="my-4">
        <h2>
          {{ t("Who can view this event and participate") }}
        </h2>
        <fieldset>
          <legend>
            {{
              t(
                "When the event is private, you'll need to share the link around."
              )
            }}
          </legend>
          <div class="field">
            <o-radio
              v-model="event.visibility"
              name="eventVisibility"
              :native-value="EventVisibility.PUBLIC"
              >{{ t("Visible everywhere on the web (public)") }}</o-radio
            >
          </div>
          <div class="field">
            <o-radio
              v-model="event.visibility"
              name="eventVisibility"
              :native-value="EventVisibility.UNLISTED"
              >{{ t("Only accessible through link (private)") }}</o-radio
            >
          </div>
        </fieldset>
        <!-- <div class="field">
          <o-radio v-model="event.visibility"
                   name="eventVisibility"
                   :native-value="EventVisibility.PRIVATE">
             {{ t('Page limited to my group (asks for auth)') }}
          </o-radio>
        </div>-->

        <o-field
          v-if="anonymousParticipationConfig?.allowed"
          :label="t('Anonymous participations')"
        >
          <o-switch v-model="eventOptions.anonymousParticipation">
            {{ t("I want to allow people to participate without an account.") }}
            <small
              v-if="
                anonymousParticipationConfig?.validation.email
                  .confirmationRequired
              "
            >
              <br />
              {{
                t(
                  "Anonymous participants will be asked to confirm their participation through e-mail."
                )
              }}
            </small>
          </o-switch>
        </o-field>

        <o-field :label="t('Participation approval')">
          <o-switch v-model="needsApproval">{{
            t("I want to approve every participation request")
          }}</o-switch>
        </o-field>

        <o-field :label="t('Number of places')">
          <o-switch v-model="limitedPlaces">{{
            t("Limited number of places")
          }}</o-switch>
        </o-field>

        <div class="" v-if="limitedPlaces">
          <o-field :label="t('Number of places')" label-for="number-of-places">
            <o-input
              type="number"
              controls-position="compact"
              :aria-minus-label="t('Decrease')"
              :aria-plus-label="t('Increase')"
              min="1"
              v-model="maximumAttendeeCapacity"
              id="number-of-places"
            />
          </o-field>
          <!--
          <o-field>
            <o-switch v-model="eventOptions.showRemainingAttendeeCapacity">
              {{ t('Show remaining number of places') }}
            </o-switch>
          </o-field>

          <o-field>
            <o-switch v-model="eventOptions.showParticipationPrice">
              {{ t('Display participation price') }}
            </o-switch>
          </o-field>-->
        </div>
      </section>
      <section class="my-4">
        <h2>{{ t("Public comment moderation") }}</h2>

        <fieldset>
          <legend>{{ t("Who can post a comment?") }}</legend>
          <o-field>
            <o-radio
              v-model="eventOptions.commentModeration"
              name="commentModeration"
              :native-value="CommentModeration.ALLOW_ALL"
              >{{ t("Allow all comments from users with accounts") }}</o-radio
            >
          </o-field>

          <!--          <div class="field">-->
          <!--            <o-radio v-model="eventOptions.commentModeration"-->
          <!--                     name="commentModeration"-->
          <!--                     :native-value="CommentModeration.MODERATED">-->
          <!--              {{ t('Moderated comments (shown after approval)') }}-->
          <!--            </o-radio>-->
          <!--          </div>-->

          <o-field>
            <o-radio
              v-model="eventOptions.commentModeration"
              name="commentModeration"
              :native-value="CommentModeration.CLOSED"
              >{{ t("Close comments for all (except for admins)") }}</o-radio
            >
          </o-field>
        </fieldset>
      </section>
      <section class="my-4">
        <h2>{{ t("Status") }}</h2>

        <fieldset>
          <legend>
            {{
              t(
                "Does the event needs to be confirmed later or is it cancelled?"
              )
            }}
          </legend>
          <o-field class="radio-buttons">
            <o-radio
              v-model="event.status"
              name="status"
              class="mr-2 p-2 rounded border"
              :class="{
                'btn-warning': event.status === EventStatus.TENTATIVE,
                'btn-outlined-warning': event.status !== EventStatus.TENTATIVE,
              }"
              variant="warning"
              :native-value="EventStatus.TENTATIVE"
            >
              <o-icon icon="calendar-question" />
              {{ t("Tentative: Will be confirmed later") }}
            </o-radio>
            <o-radio
              v-model="event.status"
              name="status"
              variant="success"
              class="mr-2 p-2 rounded border"
              :class="{
                'btn-success': event.status === EventStatus.CONFIRMED,
                'btn-outlined-success': event.status !== EventStatus.CONFIRMED,
              }"
              :native-value="EventStatus.CONFIRMED"
            >
              <o-icon icon="calendar-check" />
              {{ t("Confirmed: Will happen") }}
            </o-radio>
            <o-radio
              v-model="event.status"
              name="status"
              class="p-2 rounded border"
              :class="{
                'btn-danger': event.status === EventStatus.CANCELLED,
                'btn-outlined-danger': event.status !== EventStatus.CANCELLED,
              }"
              variant="danger"
              :native-value="EventStatus.CANCELLED"
            >
              <o-icon icon="calendar-remove" />
              {{ t("Cancelled: Won't happen") }}
            </o-radio>
          </o-field>
        </fieldset>
      </section>
    </form>
  </div>
  <div class="container mx-auto" v-else>
    <o-notification variant="danger">
      {{ t("Only group moderators can create, edit and delete events.") }}
    </o-notification>
  </div>
  <o-modal
    v-model:active="dateSettingsIsOpen"
    has-modal-card
    trap-focus
    :close-button-aria-label="t('Close')"
  >
    <form class="p-3">
      <header class="">
        <h2 class="">{{ t("Date and time settings") }}</h2>
      </header>
      <section class="">
        <p>
          {{
            t(
              "Event timezone will default to the timezone of the event's address if there is one, or to your own timezone setting."
            )
          }}
        </p>
        <o-field :label="t('Timezone')" label-for="timezone" expanded>
          <o-select
            :placeholder="t('Select a timezone')"
            :loading="timezoneLoading"
            v-model="timezone"
            id="timezone"
          >
            <optgroup
              :label="group"
              v-for="(groupTimezones, group) in timezones"
              :key="group"
            >
              <option
                v-for="timezone in groupTimezones"
                :value="`${group}/${timezone}`"
                :key="timezone"
              >
                {{ sanitizeTimezone(timezone) }}
              </option>
            </optgroup>
          </o-select>
          <o-button
            :disabled="!timezone"
            @click="timezone = null"
            class="reset-area"
            icon-left="close"
            :title="t('Clear timezone field')"
          />
        </o-field>
        <o-field :label="t('Event page settings')">
          <o-switch v-model="eventOptions.showStartTime">{{
            t("Show the time when the event begins")
          }}</o-switch>
        </o-field>
        <o-field>
          <o-switch v-model="eventOptions.showEndTime">{{
            t("Show the time when the event ends")
          }}</o-switch>
        </o-field>
      </section>
      <footer class="mt-2">
        <o-button @click="dateSettingsIsOpen = false">
          {{ t("OK") }}
        </o-button>
      </footer>
    </form>
  </o-modal>
  <span ref="bottomObserver" />
  <nav
    role="navigation"
    aria-label="main navigation"
    class="bg-mbz-yellow-alt-200 py-3"
    :class="{ 'is-fixed-bottom': showFixedNavbar }"
    v-if="hasCurrentActorPermissionsToEdit"
  >
    <div class="container mx-auto">
      <div class="flex justify-between items-center">
        <span class="dark:text-gray-900" v-if="isEventModified">
          {{ t("Unsaved changes") }}
        </span>
        <div class="flex flex-wrap gap-3 items-center">
          <o-button
            variant="text"
            @click="confirmGoBack"
            class="dark:!text-black"
            >{{ t("Cancel") }}</o-button
          >
          <!-- If an event has been published we can't make it draft anymore -->
          <span class="" v-if="event.draft === true">
            <o-button
              variant="primary"
              outlined
              @click="createOrUpdateDraft"
              :disabled="saving"
              >{{ t("Save draft") }}</o-button
            >
          </span>
          <span class="">
            <o-button
              variant="primary"
              :disabled="saving"
              @click="createOrUpdatePublish"
              @keyup.enter="createOrUpdatePublish"
            >
              <span v-if="isUpdate === false">{{ t("Create my event") }}</span>
              <span v-else-if="event.draft === true">{{ t("Publish") }}</span>
              <span v-else>{{ t("Update my event") }}</span>
            </o-button>
          </span>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts" setup>
import { getTimezoneOffset } from "date-fns-tz";
import PictureUpload from "@/components/PictureUpload.vue";
import EditorComponent from "@/components/TextEditor.vue";
import TagInput from "@/components/Event/TagInput.vue";
import EventMetadataList from "@/components/Event/EventMetadataList.vue";
import {
  NavigationGuardNext,
  onBeforeRouteLeave,
  RouteLocationNormalized,
  useRouter,
} from "vue-router";
import { formatList } from "@/utils/i18n";
import {
  ActorType,
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  GroupVisibility,
  MemberRole,
  ParticipantRole,
} from "@/types/enums";
import OrganizerPickerWrapper from "@/components/Event/OrganizerPickerWrapper.vue";
import {
  CREATE_EVENT,
  EDIT_EVENT,
  EVENT_PERSON_PARTICIPATION,
} from "@/graphql/event";
import {
  EventModel,
  IEditableEvent,
  IEvent,
  removeTypeName,
  toEditJSON,
} from "@/types/event.model";
import { LOGGED_USER_DRAFTS } from "@/graphql/actor";
import {
  IActor,
  IGroup,
  IPerson,
  usernameWithDomain,
  displayNameAndUsername,
} from "@/types/actor";
import {
  buildFileFromIMedia,
  buildFileVariable,
  readFileAsync,
} from "@/utils/image";
import RouteName from "@/router/name";
import "intersection-observer";
import {
  ApolloCache,
  FetchResult,
  InternalRefetchQueriesInclude,
} from "@apollo/client/core";
import cloneDeep from "lodash/cloneDeep";
import { IEventOptions } from "@/types/event-options.model";
import { IAddress } from "@/types/address.model";
import { LOGGED_USER_PARTICIPATIONS } from "@/graphql/participant";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useUserSettings } from "@/composition/apollo/user";
import {
  computed,
  inject,
  onMounted,
  ref,
  watch,
  defineAsyncComponent,
} from "vue";
import { useFetchEvent } from "@/composition/apollo/event";
import { useI18n } from "vue-i18n";
import { useGroup } from "@/composition/apollo/group";
import {
  useAnonymousParticipationConfig,
  useEventCategories,
  useFeatures,
  useTimezones,
} from "@/composition/apollo/config";
import { useMutation } from "@vue/apollo-composable";
import { fetchTags } from "@/composition/apollo/tags";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@vueuse/head";
import { useProgrammatic } from "@oruga-ui/oruga-next";
import type { Locale } from "date-fns";
import sortBy from "lodash/sortBy";

const DEFAULT_LIMIT_NUMBER_OF_PLACES = 10;

const { eventCategories } = useEventCategories();
const { anonymousParticipationConfig } = useAnonymousParticipationConfig();
const { currentActor } = useCurrentActorClient();
const { loggedUser } = useUserSettings();
const { identities } = useCurrentUserIdentities();

const { features } = useFeatures();

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

// apollo: {
//   config: CONFIG_EDIT_EVENT,
//   event: {
//     query: FETCH_EVENT,
//     variables() {
//       return {
//         uuid: this.eventId,
//       };
//     },
//     update(data) {
//       let event = data.event;
//       if (this.isDuplicate) {
//         event = { ...event, organizerActor: this.currentActor };
//       }
//       return new EventModel(event);
//     },
//     skip() {
//       return !this.eventId;
//     },
//   },
//   person: {
//     query: PERSON_STATUS_GROUP,
//     fetchPolicy: "cache-and-network",
//     variables() {
//       return {
//         id: this.currentActor.id,
//         group: usernameWithDomain(this.event?.attributedTo),
//       };
//     },
//     skip() {
//       return (
//         !this.event?.attributedTo ||
//         !this.event?.attributedTo?.preferredUsername
//       );
//     },
//   },
//   group: {
//     query: FETCH_GROUP,
//     fetchPolicy: "cache-and-network",
//     variables() {
//       return {
//         name: this.event?.attributedTo?.preferredUsername,
//       };
//     },
//     skip() {
//       return (
//         !this.event?.attributedTo ||
//         !this.event?.attributedTo?.preferredUsername
//       );
//     },
//   },
// },

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() =>
    props.isUpdate ? t("Event edition") : t("Event creation")
  ),
});

const props = withDefaults(
  defineProps<{
    eventId?: undefined | string;
    isUpdate?: boolean;
    isDuplicate?: boolean;
  }>(),
  { isUpdate: false, isDuplicate: false }
);

const eventId = computed(() => props.eventId);

const event = ref<IEditableEvent>(new EventModel());
const unmodifiedEvent = ref<IEditableEvent>(new EventModel());

const pictureFile = ref<File | null>(null);

// const canPromote = ref(true);
const limitedPlaces = ref(false);
const showFixedNavbar = ref(true);

const observer = ref<IntersectionObserver | null>(null);
const bottomObserver = ref<HTMLElement | null>(null);

const dateSettingsIsOpen = ref(false);

const saving = ref(false);

const initializeEvent = () => {
  const roundUpTo15Minutes = (time: Date) => {
    time.setMilliseconds(Math.round(time.getMilliseconds() / 1000) * 1000);
    time.setSeconds(Math.round(time.getSeconds() / 60) * 60);
    time.setMinutes(Math.round(time.getMinutes() / 15) * 15);
    return time;
  };

  const now = roundUpTo15Minutes(new Date());
  const end = new Date(now.valueOf());

  end.setUTCHours(now.getUTCHours() + 3);

  event.value.beginsOn = now.toISOString();
  event.value.endsOn = end.toISOString();
};

const organizerActor = computed({
  get(): IActor | undefined {
    if (event.value?.attributedTo?.id) {
      return event.value.attributedTo;
    }
    if (event.value?.organizerActor?.id) {
      return event.value.organizerActor;
    }
    return currentActor.value;
  },
  set(actor: IActor | undefined) {
    if (actor?.type === ActorType.GROUP) {
      event.value.attributedTo = actor as IGroup;
      event.value.organizerActor = currentActor.value;
    } else {
      event.value.attributedTo = undefined;
      event.value.organizerActor = actor;
    }
  },
});

const attributedToAGroup = computed((): boolean => {
  return event.value.attributedTo?.id !== undefined;
});

const eventOptions = computed({
  get(): IEventOptions {
    return removeTypeName(cloneDeep(event.value.options));
  },
  set(options: IEventOptions) {
    event.value.options = options;
  },
});

onMounted(async () => {
  observer.value = new IntersectionObserver(
    (entries) => {
      // eslint-disable-next-line no-restricted-syntax
      for (const entry of entries) {
        if (entry) {
          showFixedNavbar.value = !entry.isIntersecting;
        }
      }
    },
    {
      rootMargin: "-50px 0px -50px",
    }
  );
  if (bottomObserver.value) {
    observer.value.observe(bottomObserver.value);
  }

  pictureFile.value = await buildFileFromIMedia(event.value.picture);
  limitedPlaces.value = eventOptions.value.maximumAttendeeCapacity > 0;
  if (!(props.isUpdate || props.isDuplicate)) {
    initializeEvent();
  } else {
    event.value = new EventModel({
      ...event.value,
      options: cloneDeep(event.value.options),
      description: event.value.description || "",
    });
  }
  unmodifiedEvent.value = cloneDeep(event.value);
});

const createOrUpdateDraft = (e: Event): void => {
  e.preventDefault();
  if (validateForm()) {
    if (eventId.value && !props.isDuplicate) {
      updateEvent();
    } else {
      createEvent();
    }
  }
};

const createOrUpdatePublish = (e: Event): void => {
  e.preventDefault();
  if (validateForm()) {
    event.value.draft = false;
    createOrUpdateDraft(e);
  }
};

const form = ref<HTMLFormElement | null>(null);

const router = useRouter();

const validateForm = () => {
  if (!form.value) return;
  if (form.value.checkValidity()) {
    return true;
  }
  form.value.reportValidity();
  return false;
};

const {
  mutate: createEventMutation,
  onDone: onCreateEventMutationDone,
  onError: onCreateEventMutationError,
} = useMutation<{ createEvent: IEvent }>(CREATE_EVENT, () => ({
  update: (
    store: ApolloCache<{ createEvent: IEvent }>,
    { data: updatedData }: FetchResult
  ) => postCreateOrUpdate(store, updatedData?.createEvent),
  refetchQueries: ({ data: updatedData }: FetchResult) =>
    postRefetchQueries(updatedData?.createEvent),
}));

const { oruga } = useProgrammatic();

onCreateEventMutationDone(async ({ data }) => {
  oruga.notification.open({
    message: (event.value.draft
      ? t("The event has been created as a draft")
      : t("The event has been published")) as string,
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
  if (data?.createEvent) {
    await router.push({
      name: "Event",
      params: { uuid: data.createEvent.uuid },
    });
  }
});

onCreateEventMutationError((err) => {
  saving.value = false;
  console.error(err);
  handleError(err);
});

const createEvent = async (): Promise<void> => {
  saving.value = true;
  const variables = await buildVariables();

  createEventMutation(variables);
};

const {
  mutate: editEventMutation,
  onDone: onEditEventMutationDone,
  onError: onEditEventMutationError,
} = useMutation(EDIT_EVENT, () => ({
  update: (
    store: ApolloCache<{ updateEvent: IEvent }>,
    { data: updatedData }: FetchResult
  ) => postCreateOrUpdate(store, updatedData?.updateEvent),
  refetchQueries: ({ data }: FetchResult) =>
    postRefetchQueries(data?.updateEvent),
}));

onEditEventMutationDone(() => {
  oruga.notification.open({
    message: updateEventMessage.value,
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
  return router.push({
    name: "Event",
    params: { uuid: props.eventId as string },
  });
});

onEditEventMutationError((err) => {
  saving.value = false;
  handleError(err);
});

const updateEvent = async (): Promise<void> => {
  saving.value = true;
  const variables = await buildVariables();
  console.debug("update event", variables);
  editEventMutation(variables);
};

const hasCurrentActorPermissionsToEdit = computed((): boolean => {
  return !(
    props.eventId &&
    event.value?.organizerActor?.id !== undefined &&
    !identities.value
      ?.map(({ id }) => id)
      .includes(event.value?.organizerActor?.id) &&
    !hasGroupPrivileges.value
  );
});

const hasGroupPrivileges = computed((): boolean => {
  return (
    person.value?.memberships?.total !== undefined &&
    person.value?.memberships?.total > 0 &&
    [MemberRole.MODERATOR, MemberRole.ADMINISTRATOR].includes(
      person.value?.memberships?.elements[0].role
    )
  );
});

const updateEventMessage = computed((): string => {
  if (unmodifiedEvent.value.draft && !event.value.draft)
    return t("The event has been updated and published") as string;
  return (
    event.value.draft
      ? t("The draft event has been updated")
      : t("The event has been updated")
  ) as string;
});

const notifier = inject<Notifier>("notifier");

const handleError = (err: any) => {
  console.error(err);

  if (err.graphQLErrors !== undefined) {
    err.graphQLErrors.forEach(({ message }: { message: string }) => {
      notifier?.error(message);
    });
  }
};

/**
 * Put in cache the updated or created event.
 * If the event is not a draft anymore, also put in cache the participation
 */
const postCreateOrUpdate = (store: any, updatedEvent: IEvent) => {
  const resultEvent: IEvent = { ...updatedEvent };
  if (!updatedEvent.draft) {
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
};

/**
 * Refresh drafts or participation cache depending if the event is still draft or not
 */
const postRefetchQueries = (
  updatedEvent: IEvent
): InternalRefetchQueriesInclude => {
  if (updatedEvent.draft) {
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
};

const organizerActorEqualToCurrentActor = computed((): boolean => {
  return (
    currentActor.value?.id !== undefined &&
    organizerActor.value?.id === currentActor.value?.id
  );
});

/**
 * Build variables for Event GraphQL creation query
 */
const buildVariables = async () => {
  let res = {
    ...toEditJSON(new EventModel(event.value)),
    options: eventOptions.value,
  };

  const localOrganizerActor = event.value?.organizerActor?.id
    ? event.value.organizerActor
    : organizerActor.value;
  if (organizerActor.value) {
    res = { ...res, organizerActorId: localOrganizerActor?.id };
  }
  const attributedToId = event.value?.attributedTo?.id
    ? event.value?.attributedTo.id
    : null;
  res = { ...res, attributedToId };

  if (pictureFile.value) {
    const pictureObj = buildFileVariable(pictureFile.value, "picture");
    res = { ...res, ...pictureObj };
  }

  try {
    if (event.value?.picture && pictureFile.value) {
      const oldPictureFile = (await buildFileFromIMedia(
        event.value?.picture
      )) as File;
      const oldPictureFileContent = await readFileAsync(oldPictureFile);
      const newPictureFileContent = await readFileAsync(
        pictureFile.value as File
      );
      if (oldPictureFileContent === newPictureFileContent) {
        res.picture = { mediaId: event.value?.picture.id };
      }
    }
  } catch (e) {
    console.error(e);
  }
  return res;
};

watch(limitedPlaces, () => {
  if (!limitedPlaces.value) {
    eventOptions.value.maximumAttendeeCapacity = 0;
    eventOptions.value.remainingAttendeeCapacity = 0;
    eventOptions.value.showRemainingAttendeeCapacity = false;
  } else {
    eventOptions.value.maximumAttendeeCapacity =
      eventOptions.value.maximumAttendeeCapacity ||
      DEFAULT_LIMIT_NUMBER_OF_PLACES;
  }
});

const needsApproval = computed({
  get(): boolean {
    return event.value?.joinOptions == EventJoinOptions.RESTRICTED;
  },
  set(value: boolean) {
    if (value === true) {
      event.value.joinOptions = EventJoinOptions.RESTRICTED;
    } else {
      event.value.joinOptions = EventJoinOptions.FREE;
    }
  },
});

const checkTitleLength = computed((): Array<string | undefined> => {
  return event.value.title.length > 80
    ? ["info", t("The event title will be ellipsed.")]
    : [undefined, undefined];
});

const dialog = inject<Dialog>("dialog");

/**
 * Confirm cancel
 */
const confirmGoElsewhere = (): Promise<boolean> => {
  // TODO: Make calculation of changes work again and bring this back
  // If the event wasn't modified, no need to warn
  // if (!this.isEventModified) {
  //   return Promise.resolve(true);
  // }
  const title: string = props.isUpdate
    ? t("Cancel edition")
    : t("Cancel creation");
  const message: string = props.isUpdate
    ? t(
        "Are you sure you want to cancel the event edition? You'll lose all modifications.",
        { title: event.value?.title }
      )
    : t(
        "Are you sure you want to cancel the event creation? You'll lose all modifications.",
        { title: event.value?.title }
      );

  return new Promise((resolve) => {
    dialog?.confirm({
      title,
      message,
      confirmText: t("Abandon editing") as string,
      cancelText: t("Continue editing") as string,
      variant: "warning",
      hasIcon: true,
      onConfirm: () => resolve(true),
      onCancel: () => resolve(false),
    });
  });
};

/**
 * Confirm cancel
 */
const confirmGoBack = (): void => {
  router.go(-1);
};

onBeforeRouteLeave(
  async (
    to: RouteLocationNormalized,
    from: RouteLocationNormalized,
    next: NavigationGuardNext
  ) => {
    if (to.name === RouteName.EVENT) return next();
    if (await confirmGoElsewhere()) {
      return next();
    }
    return next(false);
  }
);

const isEventModified = computed((): boolean => {
  return (
    event.value &&
    unmodifiedEvent.value &&
    JSON.stringify(toEditJSON(event.value)) !==
      JSON.stringify(unmodifiedEvent.value)
  );
});

const beginsOn = computed({
  get(): Date | null {
    // if (this.timezone && this.event.beginsOn) {
    //   return utcToZonedTime(this.event.beginsOn, this.timezone);
    // }
    return event.value.beginsOn ? new Date(event.value.beginsOn) : null;
  },
  set(newBeginsOn: Date | null) {
    event.value.beginsOn = newBeginsOn?.toISOString() ?? null;
    if (!event.value.endsOn || !newBeginsOn) return;
    const dateBeginsOn = new Date(newBeginsOn);
    const dateEndsOn = new Date(event.value.endsOn);
    let endsOn = new Date(event.value.endsOn);
    if (dateEndsOn < dateBeginsOn) {
      endsOn = dateBeginsOn;
      endsOn.setHours(dateBeginsOn.getHours() + 1);
    }
    if (dateEndsOn === dateBeginsOn) {
      endsOn.setHours(dateEndsOn.getHours() + 1);
    }
    event.value.endsOn = endsOn.toISOString();
  },
});

const endsOn = computed({
  get(): Date | null {
    // if (this.event.endsOn && this.timezone) {
    //   return utcToZonedTime(this.event.endsOn, this.timezone);
    // }
    return event.value.endsOn ? new Date(event.value.endsOn) : null;
  },
  set(newEndsOn: Date | null) {
    event.value.endsOn = newEndsOn?.toISOString() ?? null;
  },
});

const { timezones: rawTimezones, loading: timezoneLoading } = useTimezones();

const timezones = computed((): Record<string, string[]> => {
  return (rawTimezones.value || []).reduce(
    (acc: { [key: string]: Array<string> }, val: string) => {
      const components = val.split("/");
      const [prefix, suffix] = [
        components.shift() as string,
        components.join("/"),
      ];
      const pushOrCreate = (
        acc2: { [key: string]: Array<string> },
        prefix2: string,
        suffix2: string
      ) => {
        // eslint-disable-next-line no-param-reassign
        (acc2[prefix2] = acc2[prefix2] || []).push(suffix2);
        return acc2;
      };
      if (suffix) {
        return pushOrCreate(acc, prefix, suffix);
      }
      return pushOrCreate(acc, t("Other") as string, prefix);
    },
    {}
  );
});

// eslint-disable-next-line class-methods-use-this
const sanitizeTimezone = (timezone: string): string => {
  return timezone
    .split("_")
    .join(" ")
    .replace("St ", "St. ")
    .split("/")
    .join(" - ");
};

const timezone = computed({
  get(): string | null {
    return event.value.options.timezone;
  },
  set(newTimezone: string | null) {
    event.value.options = {
      ...event.value.options,
      timezone: newTimezone,
    };
  },
});

const userTimezone = computed((): string | undefined => {
  return loggedUser.value?.settings?.timezone;
});

const userActualTimezone = computed((): string => {
  if (userTimezone.value) {
    return userTimezone.value;
  }
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
});

const tzOffset = (date: Date | null): number => {
  if (timezone.value && date) {
    const eventUTCOffset = getTimezoneOffset(timezone.value, date);
    const localUTCOffset = getTimezoneOffset(userActualTimezone.value, date);
    return (eventUTCOffset - localUTCOffset) / (60 * 1000);
  }
  return 0;
};

const eventPhysicalAddress = computed({
  get(): IAddress | null {
    return event.value.physicalAddress;
  },
  set(address: IAddress | null) {
    if (address && address.timezone) {
      timezone.value = address.timezone;
    }
    event.value.physicalAddress = address;
  },
});

const isOnline = computed({
  get(): boolean {
    return event.value.options.isOnline;
  },
  set(newIsOnline: boolean) {
    event.value.options = {
      ...event.value.options,
      isOnline: newIsOnline,
    };
  },
});

watch(isOnline, (newIsOnline) => {
  if (newIsOnline === true) {
    eventPhysicalAddress.value = null;
  }
});

const maximumAttendeeCapacity = computed({
  get(): string {
    return eventOptions.value.maximumAttendeeCapacity.toString();
  },
  set(newMaximumAttendeeCapacity: string) {
    eventOptions.value.maximumAttendeeCapacity = parseInt(
      newMaximumAttendeeCapacity
    );
  },
});

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const firstDayOfWeek = computed((): number => {
  return dateFnsLocale?.options?.weekStartsOn || 0;
});

const { event: fetchedEvent, onResult: onFetchEventResult } = useFetchEvent(
  eventId.value
);

watch(
  fetchedEvent,
  () => {
    if (!fetchedEvent.value) return;
    event.value = { ...fetchedEvent.value };
  },
  { immediate: true }
);

onFetchEventResult((result) => {
  if (!result.loading && result.data?.event) {
    event.value = { ...result.data?.event };
  }
});

const groupFederatedUsername = computed(() =>
  usernameWithDomain(fetchedEvent.value?.attributedTo)
);

const { person } = usePersonStatusGroup(groupFederatedUsername);

const { group } = useGroup(groupFederatedUsername);

watch(group, () => {
  if (!props.isUpdate && group.value?.visibility == GroupVisibility.UNLISTED) {
    event.value.visibility = EventVisibility.UNLISTED;
  }
  if (!props.isUpdate && group.value?.visibility == GroupVisibility.PUBLIC) {
    event.value.visibility = EventVisibility.PUBLIC;
  }
});

const orderedCategories = computed(() => {
  if (!eventCategories.value) return undefined;
  return sortBy(eventCategories.value, ["label"]);
});
</script>

<style lang="scss">
.radio-buttons input[type="radio"] {
  & {
    display: none;
  }

  & + span.radio-label {
    padding-left: 3px;
  }
}
</style>
