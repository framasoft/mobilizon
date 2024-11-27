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

      <o-field :label="t('Headline picture')">
        <picture-upload
          v-model:modelValue="pictureFile"
          :textFallback="t('Headline picture')"
          :defaultImage="event.picture"
        />
      </o-field>

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
          expanded
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
        <tag-input v-model="event.tags" class="flex-1" />
      </div>

      <o-field
        grouped
        groupMultiline
        :label="t('Starts on…')"
        class="items-center"
        label-for="begins-on-field"
      >
        <event-date-picker
          :time="showStartTime"
          v-model="beginsOn"
          @blur="consistencyBeginsOnBeforeEndsOn"
        ></event-date-picker>
        <div class="my-2">
          <o-switch v-model="showStartTime">{{
            t("Show the time when the event begins")
          }}</o-switch>
        </div>
      </o-field>

      <o-field
        grouped
        groupMultiline
        :label="t('Ends on…')"
        label-for="ends-on-field"
        class="items-center"
      >
        <event-date-picker
          :time="showEndTime"
          v-model="endsOn"
          @blur="consistencyBeginsOnBeforeEndsOn"
          :min="beginsOn"
        ></event-date-picker>
        <div class="my-2">
          <o-switch v-model="showEndTime">{{
            t("Show the time when the event ends")
          }}</o-switch>
        </div>
      </o-field>

      <o-button class="block" variant="text" @click="dateSettingsIsOpen = true">
        {{ t("Timezone parameters") }}
      </o-button>

      <div class="my-6">
        <full-address-auto-complete
          v-model="eventPhysicalAddress"
          :user-timezone="userActualTimezone"
          :disabled="event.options.isOnline"
          :allowManualDetails="true"
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
          :current-actor="currentActor as IPerson"
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
          expanded
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
                        escapeHtml(displayNameAndUsername(contact))
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
      </section>
      <section class="my-4">
        <h2>
          {{ t("How to register") }}
        </h2>

        <div class="field">
          <o-radio
            v-model="registerOption"
            name="registerOption"
            :native-value="RegisterOption.MOBILIZON"
            >{{ t("I want to manage the registration on Mobilizon") }}</o-radio
          >
        </div>

        <div class="field">
          <o-radio
            v-model="registerOption"
            name="registerOption"
            :native-value="RegisterOption.EXTERNAL"
            >{{
              t("I want to manage the registration with an external provider")
            }}</o-radio
          >
        </div>

        <o-field
          v-if="registerOption === RegisterOption.EXTERNAL"
          :label="t('URL')"
        >
          <o-input
            icon="link"
            type="url"
            v-model="event.externalParticipationUrl"
            :placeholder="t('External provider URL')"
            required
          />
        </o-field>

        <o-field
          v-if="
            anonymousParticipationConfig?.allowed &&
            registerOption === RegisterOption.MOBILIZON
          "
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

        <o-field
          :label="t('Participation approval')"
          v-show="registerOption === RegisterOption.MOBILIZON"
        >
          <o-switch v-model="needsApproval">{{
            t("I want to approve every participation request")
          }}</o-switch>
        </o-field>

        <o-field
          :label="t('Showing participants')"
          v-show="registerOption === RegisterOption.MOBILIZON"
        >
          <o-switch v-model="hideParticipants">{{
            t("Hide the number of participants")
          }}</o-switch>
        </o-field>

        <o-field
          :label="t('Number of places')"
          v-show="registerOption === RegisterOption.MOBILIZON"
        >
          <o-switch v-model="limitedPlaces">{{
            t("Limited number of places")
          }}</o-switch>
        </o-field>

        <div
          class=""
          v-if="limitedPlaces && registerOption === RegisterOption.MOBILIZON"
        >
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

        <fieldset id="status">
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
              variant="warning"
              :native-value="EventStatus.TENTATIVE"
            >
              <div
                class="mr-2 p-2 rounded border flex gap-x-1"
                :class="{
                  'btn-warning': event.status === EventStatus.TENTATIVE,
                  'btn-outlined-warning':
                    event.status !== EventStatus.TENTATIVE,
                }"
              >
                <o-icon icon="calendar-question" />
                {{ t("Tentative: Will be confirmed later") }}
              </div>
            </o-radio>
            <o-radio
              v-model="event.status"
              name="status"
              variant="success"
              :native-value="EventStatus.CONFIRMED"
            >
              <div
                class="mr-2 p-2 rounded border flex gap-x-1"
                :class="{
                  'btn-success': event.status === EventStatus.CONFIRMED,
                  'btn-outlined-success':
                    event.status !== EventStatus.CONFIRMED,
                }"
              >
                <o-icon icon="calendar-check" />
                {{ t("Confirmed: Will happen") }}
              </div>
            </o-radio>
            <o-radio
              v-model="event.status"
              name="status"
              variant="danger"
              :native-value="EventStatus.CANCELLED"
            >
              <div
                class="p-2 rounded border flex gap-x-1"
                :class="{
                  'btn-danger': event.status === EventStatus.CANCELLED,
                  'btn-outlined-danger': event.status !== EventStatus.CANCELLED,
                }"
              >
                <o-icon icon="calendar-remove" />
                {{ t("Cancelled: Won't happen") }}
              </div>
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
        <h2 class="">{{ t("Timezone") }}</h2>
      </header>
      <section class="">
        <p>
          {{
            t(
              "Event timezone will default to the timezone of the event's address if there is one, or to your own timezone setting."
            )
          }}
        </p>
        <o-field expanded>
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
                :value="
                  group === t('Other') ? timezone : `${group}/${timezone}`
                "
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
    class="bg-mbz-yellow-alt-200 p-3 mt-3 rounded"
    :class="{ 'is-fixed-bottom': showFixedNavbar }"
    v-if="hasCurrentActorPermissionsToEdit"
  >
    <div class="container mx-auto">
      <div class="lg:flex lg:justify-between lg:items-center lg:flex-wrap">
        <div
          class="text-red-900 text-center w-full margin m-1 lg:m-0 lg:w-auto lg:text-left"
          v-if="isEventModified"
        >
          {{ t("Unsaved changes") }}
        </div>
        <div class="flex flex-wrap gap-3 items-center justify-end">
          <o-button
            expanded
            variant="text"
            @click="confirmGoBack"
            class="dark:!text-black ml-auto"
            >{{ t("Cancel") }}</o-button
          >
          <!-- If an event has been published we can't make it draft anymore -->
          <o-button
            v-if="event.draft === true"
            expanded
            variant="primary"
            class="!text-black hover:!text-white"
            outlined
            @click="createOrUpdateDraft"
            :disabled="saving"
            :loading="saving"
            >{{ t("Save draft") }}</o-button
          >
          <o-button
            expanded
            variant="primary"
            :disabled="saving"
            :loading="saving"
            @click="createOrUpdatePublish"
            @keyup.enter="createOrUpdatePublish"
          >
            <span v-if="isUpdate === false">{{ t("Create my event") }}</span>
            <span v-else-if="event.draft === true">{{ t("Publish") }}</span>
            <span v-else>{{ t("Update my event") }}</span>
          </o-button>
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
import { useLoggedUser } from "@/composition/apollo/user";
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
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@/utils/head";
import { useOruga } from "@oruga-ui/oruga-next";
import sortBy from "lodash/sortBy";
import { escapeHtml } from "@/utils/html";
import EventDatePicker from "@/components/Event/EventDatePicker.vue";

const DEFAULT_LIMIT_NUMBER_OF_PLACES = 10;

const { eventCategories } = useEventCategories();
const { anonymousParticipationConfig } = useAnonymousParticipationConfig();
const { currentActor } = useCurrentActorClient();
const { loggedUser } = useLoggedUser();
const { identities } = useCurrentUserIdentities();

const { features } = useFeatures();

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const { t } = useI18n({ useScope: "global" });

const props = withDefaults(
  defineProps<{
    eventId?: undefined | string;
    isUpdate?: boolean;
    isDuplicate?: boolean;
  }>(),
  { isUpdate: false, isDuplicate: false }
);

const eventId = computed(() => props.eventId);

useHead({
  title: computed(() =>
    props.isUpdate ? t("Event edition") : t("Event creation")
  ),
});

const event = ref<IEditableEvent>(new EventModel());
const unmodifiedEvent = ref<IEditableEvent>(new EventModel());

const pictureFile = ref<File | null>(null);

const limitedPlaces = ref(false);
const showFixedNavbar = ref(true);

const observer = ref<IntersectionObserver | null>(null);
const bottomObserver = ref<HTMLElement | null>(null);

const dateSettingsIsOpen = ref(false);

const saving = ref(false);

const setEventTimezoneToUserTimezoneIfUnset = () => {
  if (userTimezone.value && event.value.options.timezone == null) {
    event.value.options.timezone = userTimezone.value;
  }
};

// usefull if the page is loaded from scratch
watch(loggedUser, setEventTimezoneToUserTimezoneIfUnset);

const initializeNewEvent = () => {
  // usefull if the data is already cached
  setEventTimezoneToUserTimezoneIfUnset();

  // Default values for beginsOn and endsOn

  const roundUpTo15Minutes = (time: Date) => {
    time.setUTCMilliseconds(
      Math.round(time.getUTCMilliseconds() / 1000) * 1000
    );
    time.setUTCSeconds(Math.round(time.getUTCSeconds() / 60) * 60);
    time.setUTCMinutes(Math.round(time.getUTCMinutes() / 15) * 15);
    return time;
  };

  const now = roundUpTo15Minutes(new Date());
  const end = new Date(now.valueOf());

  end.setUTCHours(now.getUTCHours() + 3);

  beginsOn.value = now;
  endsOn.value = end;

  // Default values for showStartTime and showEndTime
  showStartTime.value = false;
  showEndTime.value = false;

  // Default values for hideParticipants
  hideParticipants.value = true;
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
    initializeNewEvent();
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

const { notification } = useOruga();

onCreateEventMutationDone(async ({ data }) => {
  notification.open({
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
  notification.open({
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
    err.graphQLErrors.forEach(
      ({
        message,
        field,
      }: {
        message: string | { slug?: string[] }[];
        field: string;
      }) => {
        if (
          field === "tags" &&
          Array.isArray(message) &&
          message.some((msg) => msg.slug)
        ) {
          const finalMsg = message.find((msg) => msg.slug?.[0]);
          notifier?.error(
            t("Error while adding tag: {error}", { error: finalMsg?.slug?.[0] })
          );
        } else if (typeof message === "string") {
          notifier?.error(message);
        }
      }
    );
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
    console.debug("builded variables", res);
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

const hideParticipants = computed({
  get(): boolean {
    return event.value?.options.hideNumberOfParticipants;
  },
  set(value: boolean) {
    event.value.options.hideNumberOfParticipants = value;
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

const showStartTime = computed({
  get(): boolean {
    return event.value.options.showStartTime;
  },
  set(newShowStartTime: boolean) {
    event.value.options = {
      ...event.value.options,
      showStartTime: newShowStartTime,
    };
  },
});

const showEndTime = computed({
  get(): boolean {
    return event.value.options.showEndTime;
  },
  set(newshowEndTime: boolean) {
    event.value.options = {
      ...event.value.options,
      showEndTime: newshowEndTime,
    };
  },
});

const beginsOn = ref(new Date());
const endsOn = ref(new Date());

const updateEventDateRelatedToTimezone = () => {
  // update event.value.beginsOn taking care of timezone
  if (beginsOn.value) {
    const dateBeginsOn = new Date(beginsOn.value.getTime());
    dateBeginsOn.setUTCMinutes(dateBeginsOn.getUTCMinutes() - tzOffset.value);
    event.value.beginsOn = dateBeginsOn.toISOString();
  }

  if (endsOn.value) {
    // update event.value.endsOn taking care of timezone
    const dateEndsOn = new Date(endsOn.value.getTime());
    dateEndsOn.setUTCMinutes(dateEndsOn.getUTCMinutes() - tzOffset.value);
    event.value.endsOn = dateEndsOn.toISOString();
  }
};

watch(beginsOn, (newBeginsOn) => {
  if (!newBeginsOn) {
    event.value.beginsOn = null;
    return;
  }

  // usefull for comparaison
  newBeginsOn.setUTCSeconds(0);
  newBeginsOn.setUTCMilliseconds(0);

  // update event.value.beginsOn taking care of timezone
  updateEventDateRelatedToTimezone();
});

watch(endsOn, (newEndsOn) => {
  if (!newEndsOn) {
    event.value.endsOn = null;
    return;
  }

  // usefull for comparaison
  newEndsOn.setUTCSeconds(0);
  newEndsOn.setUTCMilliseconds(0);

  // update event.value.endsOn taking care of timezone
  updateEventDateRelatedToTimezone();
});

/* 
For endsOn, we need to check consistencyBeginsOnBeforeEndsOn() at blur
because the datetime-local component update itself immediately
Ex : your event start at 10:00 and stops at 12:00
To type "10" hours, you will first have "1" hours, then "10" hours
So you cannot check consistensy in real time, only onBlur because of the moment we falsely have "1:00"
 */
const consistencyBeginsOnBeforeEndsOn = () => {
  // Update endsOn to make sure endsOn is later than beginsOn
  if (endsOn.value && beginsOn.value && endsOn.value <= beginsOn.value) {
    const newEndsOn = new Date(beginsOn.value);
    newEndsOn.setUTCHours(beginsOn.value.getUTCHours() + 1);
    endsOn.value = newEndsOn;
  }
};

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

// Timezone specified in user settings
const userTimezone = computed((): string | undefined => {
  return loggedUser.value?.settings?.timezone;
});

const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

// Timezone specified in user settings or local timezone browser if unavailable
const userActualTimezone = computed((): string => {
  if (userTimezone.value) {
    return userTimezone.value;
  }
  return browserTimeZone;
});

const tzOffset = computed((): number => {
  if (!timezone.value) {
    return 0;
  }

  const date = new Date();

  // diff between UTC and selected timezone
  // example: Asia/Shanghai is + 8 hours
  const eventUTCOffset = getTimezoneOffset(timezone.value, date);

  // diff between UTC and local browser timezone
  // example: Europe/Paris is + 1 hour (or +2 depending of daylight saving time)
  const localUTCOffset = getTimezoneOffset(browserTimeZone, date);

  // example : offset is 8-1=7
  return (eventUTCOffset - localUTCOffset) / (60 * 1000);
});

watch(tzOffset, () => {
  // tzOffset has been changed, we need to update the event dates
  updateEventDateRelatedToTimezone();
});

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

const { event: fetchedEvent, onResult: onFetchEventResult } = useFetchEvent(
  eventId.value
);

// update the date components if the event changed (after fetching it, for example)
watch(event, () => {
  if (event.value.beginsOn) {
    const date = new Date(event.value.beginsOn);
    date.setUTCMinutes(date.getUTCMinutes() + tzOffset.value);
    beginsOn.value = date;
  }
  if (event.value.endsOn) {
    const date = new Date(event.value.endsOn);
    date.setUTCMinutes(date.getUTCMinutes() + tzOffset.value);
    endsOn.value = date;
  }
});

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

const RegisterOption = {
  MOBILIZON: "mobilizon",
  EXTERNAL: "external",
};

const registerOption = computed({
  get() {
    return event.value?.joinOptions === EventJoinOptions.EXTERNAL
      ? RegisterOption.EXTERNAL
      : RegisterOption.MOBILIZON;
  },
  set(newValue) {
    if (newValue === RegisterOption.EXTERNAL) {
      event.value.joinOptions = EventJoinOptions.EXTERNAL;
    } else {
      event.value.joinOptions = EventJoinOptions.FREE;
    }
  },
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

#status .o-field--addons {
  flex-wrap: wrap;
  gap: 5px;
}

#status .o-field--addons > label {
  flex: 1 1 0;
  margin: 0;
}
#status .o-field--addons .mr-2 {
  margin: 0;
}

#status .o-field--addons > label .o-radio__label {
  width: 100%;
}

@media screen and (max-width: 700px) {
  #status .o-field--addons {
    flex-direction: column;
  }
}
</style>
