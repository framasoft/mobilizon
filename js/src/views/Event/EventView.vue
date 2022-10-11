<template>
  <div class="container mx-auto">
    <o-loading v-model:active="eventLoading" />
    <div class="wrapper mb-3">
      <event-banner :picture="event?.picture" />
      <div class="intro-wrapper">
        <div class="date-calendar-icon-wrapper" v-if="event?.beginsOn">
          <date-calendar-icon :date="event.beginsOn.toString()" />
        </div>

        <section class="intro" dir="auto">
          <div class="flex flex-wrap">
            <div class="flex-1 min-w-fit">
              <h1
                class="text-4xl font-bold m-0"
                dir="auto"
                :lang="event?.language"
              >
                {{ event?.title }}
              </h1>
              <div class="organizer">
                <div v-if="event?.organizerActor && !event?.attributedTo">
                  <popover-actor-card
                    :actor="event.organizerActor"
                    :inline="true"
                  >
                    <i18n-t
                      keypath="By {username}"
                      dir="auto"
                      class="block truncate max-w-xs md:max-w-sm"
                    >
                      <template #username>
                        <span dir="ltr">{{
                          displayName(event.organizerActor)
                        }}</span>
                      </template>
                    </i18n-t>
                  </popover-actor-card>
                </div>
                <span v-else-if="event?.attributedTo">
                  <popover-actor-card
                    :actor="event.attributedTo"
                    :inline="true"
                  >
                    <i18n-t
                      keypath="By {group}"
                      dir="auto"
                      class="block truncate max-w-xs md:max-w-sm"
                    >
                      <template #group>
                        <router-link
                          :to="{
                            name: RouteName.GROUP,
                            params: {
                              preferredUsername: usernameWithDomain(
                                event.attributedTo
                              ),
                            },
                          }"
                          dir="ltr"
                          >{{ displayName(event.attributedTo) }}</router-link
                        >
                      </template>
                    </i18n-t>
                  </popover-actor-card>
                </span>
              </div>
              <div class="inline-flex items-center gap-1">
                <p v-if="event?.status !== EventStatus.CONFIRMED">
                  <tag
                    variant="warning"
                    v-if="event?.status === EventStatus.TENTATIVE"
                    >{{ t("Event to be confirmed") }}</tag
                  >
                  <tag
                    variant="danger"
                    v-if="event?.status === EventStatus.CANCELLED"
                    >{{ t("Event cancelled") }}</tag
                  >
                </p>
                <p class="flex gap-1 items-center" dir="auto">
                  <tag v-if="eventCategory" class="category" capitalize>{{
                    eventCategory
                  }}</tag>
                  <router-link
                    v-for="tag in event?.tags ?? []"
                    :key="tag.title"
                    :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
                  >
                    <tag>{{ tag.title }}</tag>
                  </router-link>
                </p>
                <tag variant="warning" size="medium" v-if="event?.draft"
                  >{{ t("Draft") }}
                </tag>
              </div>
            </div>

            <div class="">
              <participation-section
                v-if="
                  event &&
                  currentActor &&
                  identities &&
                  anonymousParticipationConfig
                "
                :participation="participations[0]"
                :event="event"
                :anonymousParticipation="anonymousParticipation"
                :currentActor="currentActor"
                :identities="identities"
                :anonymousParticipationConfig="anonymousParticipationConfig"
                @join-event="joinEvent"
                @join-modal="isJoinModalActive = true"
                @join-event-with-confirmation="joinEventWithConfirmation"
                @confirm-leave="confirmLeave"
                @cancel-anonymous-participation="cancelAnonymousParticipation"
              />
              <div class="flex flex-col">
                <template v-if="!event?.draft">
                  <p
                    v-if="event?.visibility === EventVisibility.PUBLIC"
                    class="inline-flex gap-1"
                  >
                    <Earth />
                    {{ t("Public event") }}
                  </p>
                  <p
                    v-if="event?.visibility === EventVisibility.UNLISTED"
                    class="inline-flex gap-1"
                  >
                    <Link />
                    {{ t("Private event") }}
                  </p>
                </template>
                <template v-if="!event?.local && organizer?.domain">
                  <a :href="event?.url">
                    <tag>{{ organizer?.domain }}</tag>
                  </a>
                </template>
                <p class="inline-flex gap-1">
                  <TicketConfirmationOutline />
                  <router-link
                    class="participations-link"
                    v-if="canManageEvent && event?.draft === false"
                    :to="{
                      name: RouteName.PARTICIPATIONS,
                      params: { eventId: event.uuid },
                    }"
                  >
                    <!-- We retire one because of the event creator who is a
                    participant -->
                    <span v-if="maximumAttendeeCapacity">
                      {{
                        t(
                          "{available}/{capacity} available places",
                          {
                            available:
                              maximumAttendeeCapacity -
                              event.participantStats.participant,
                            capacity: maximumAttendeeCapacity,
                          },
                          maximumAttendeeCapacity -
                            event.participantStats.participant
                        )
                      }}
                    </span>
                    <span v-else>
                      {{
                        t(
                          "No one is participating|One person participating|{going} people participating",
                          {
                            going: event.participantStats.participant,
                          },
                          event.participantStats.participant
                        )
                      }}
                    </span>
                  </router-link>
                  <span v-else>
                    <span v-if="maximumAttendeeCapacity">
                      {{
                        t(
                          "{available}/{capacity} available places",
                          {
                            available:
                              maximumAttendeeCapacity -
                              (event?.participantStats.participant ?? 0),
                            capacity: maximumAttendeeCapacity,
                          },
                          maximumAttendeeCapacity -
                            (event?.participantStats.participant ?? 0)
                        )
                      }}
                    </span>
                    <span v-else>
                      {{
                        t(
                          "No one is participating|One person participating|{going} people participating",
                          {
                            going: event?.participantStats.participant,
                          },
                          event?.participantStats.participant ?? 0
                        )
                      }}
                    </span>
                  </span>
                  <VTooltip v-if="event?.local === false">
                    <HelpCircleOutline :size="16" />
                    <template #popper>
                      {{
                        t(
                          "The actual number of participants may differ, as this event is hosted on another instance."
                        )
                      }}
                    </template>
                  </VTooltip>
                </p>
                <o-dropdown>
                  <template #trigger>
                    <o-button icon-right="dots-horizontal">
                      {{ t("Actions") }}
                    </o-button>
                  </template>
                  <o-dropdown-item
                    aria-role="listitem"
                    has-link
                    v-if="canManageEvent || event?.draft"
                  >
                    <router-link
                      class="flex gap-1"
                      :to="{
                        name: RouteName.EDIT_EVENT,
                        params: { eventId: event?.uuid },
                      }"
                    >
                      <Pencil />
                      {{ t("Edit") }}
                    </router-link>
                  </o-dropdown-item>
                  <o-dropdown-item
                    aria-role="listitem"
                    has-link
                    v-if="canManageEvent || event?.draft"
                  >
                    <router-link
                      class="flex gap-1"
                      :to="{
                        name: RouteName.DUPLICATE_EVENT,
                        params: { eventId: event?.uuid },
                      }"
                    >
                      <ContentDuplicate />
                      {{ t("Duplicate") }}
                    </router-link>
                  </o-dropdown-item>
                  <o-dropdown-item
                    aria-role="listitem"
                    v-if="canManageEvent || event?.draft"
                    @click="openDeleteEventModal"
                    @keyup.enter="openDeleteEventModal"
                    ><span class="flex gap-1">
                      <Delete />
                      {{ t("Delete") }}
                    </span>
                  </o-dropdown-item>

                  <hr
                    role="presentation"
                    class="dropdown-divider"
                    aria-role="o-dropdown-item"
                    v-if="canManageEvent || event?.draft"
                  />
                  <o-dropdown-item
                    aria-role="listitem"
                    v-if="event?.draft === false"
                    @click="triggerShare()"
                    @keyup.enter="triggerShare()"
                    class="p-1"
                  >
                    <span class="flex gap-1">
                      <Share />
                      {{ t("Share this event") }}
                    </span>
                  </o-dropdown-item>
                  <o-dropdown-item
                    aria-role="listitem"
                    @click="downloadIcsEvent()"
                    @keyup.enter="downloadIcsEvent()"
                    v-if="event?.draft === false"
                  >
                    <span class="flex gap-1">
                      <CalendarPlus />
                      {{ t("Add to my calendar") }}
                    </span>
                  </o-dropdown-item>
                  <o-dropdown-item
                    aria-role="listitem"
                    v-if="ableToReport"
                    @click="isReportModalActive = true"
                    @keyup.enter="isReportModalActive = true"
                    class="p-1"
                  >
                    <span class="flex gap-1">
                      <Flag />
                      {{ t("Report") }}
                    </span>
                  </o-dropdown-item>
                </o-dropdown>
              </div>
            </div>
          </div>
        </section>
      </div>

      <div
        class="event-description-wrapper rounded-lg dark:border-violet-title flex flex-wrap flex-col md:flex-row-reverse"
      >
        <aside class="event-metadata rounded dark:bg-gray-600 shadow-md">
          <div class="sticky">
            <event-metadata-sidebar
              v-if="event"
              :event="event"
              :user="loggedUser"
              @showMapModal="showMap = true"
            />
          </div>
        </aside>
        <div class="event-description-comments">
          <section class="event-description">
            <h2 class="text-xl">{{ t("About this event") }}</h2>
            <p v-if="!event?.description">
              {{ t("The event organizer didn't add any description.") }}
            </p>
            <div v-else>
              <div
                :lang="event?.language"
                dir="auto"
                class="description-content"
                ref="eventDescriptionElement"
                v-html="event.description"
              />
            </div>
          </section>
          <section class="integration-wrappers">
            <component
              v-for="(metadata, integration) in integrations"
              :is="integration"
              :key="integration"
              :metadata="metadata"
            />
          </section>
          <section class="comments" ref="commentsObserver">
            <a href="#comments">
              <h2 class="text-xl" id="comments">{{ t("Comments") }}</h2>
            </a>
            <comment-tree v-if="event && loadComments" :event="event" />
          </section>
        </div>
      </div>

      <section class="" v-if="(event?.relatedEvents ?? []).length > 0">
        <h2 class="">
          {{ t("These events may interest you") }}
        </h2>
        <multi-card :events="event?.relatedEvents ?? []" />
      </section>
      <o-modal
        v-model:active="isReportModalActive"
        has-modal-card
        ref="reportModal"
        :close-button-aria-label="t('Close')"
      >
        <ReportModal
          :on-confirm="reportEvent"
          :title="t('Report this event')"
          :outside-domain="organizerDomain"
        />
      </o-modal>
      <o-modal
        :close-button-aria-label="t('Close')"
        v-model:active="isShareModalActive"
        has-modal-card
        ref="shareModal"
      >
        <share-event-modal
          v-if="event"
          :event="event"
          :eventCapacityOK="eventCapacityOK"
        />
      </o-modal>
      <o-modal
        v-model:active="isJoinModalActive"
        has-modal-card
        ref="participationModal"
        :close-button-aria-label="t('Close')"
      >
        <identity-picker v-if="identity" v-model="identity">
          <template #footer>
            <footer class="flex gap-2">
              <o-button
                outlined
                ref="cancelButton"
                @click="isJoinModalActive = false"
                @keyup.enter="isJoinModalActive = false"
              >
                {{ t("Cancel") }}
              </o-button>
              <o-button
                v-if="identity"
                variant="primary"
                ref="confirmButton"
                @click="
                  event?.joinOptions === EventJoinOptions.RESTRICTED
                    ? joinEventWithConfirmation(identity as IPerson)
                    : joinEvent(identity as IPerson)
                "
                @keyup.enter="
                  event?.joinOptions === EventJoinOptions.RESTRICTED
                    ? joinEventWithConfirmation(identity as IPerson)
                    : joinEvent(identity as IPerson)
                "
              >
                {{ t("Confirm my particpation") }}
              </o-button>
            </footer>
          </template>
        </identity-picker>
      </o-modal>
      <o-modal
        v-model:active="isJoinConfirmationModalActive"
        has-modal-card
        ref="joinConfirmationModal"
        :close-button-aria-label="t('Close')"
      >
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              {{ t("Participation confirmation") }}
            </p>
          </header>

          <section class="modal-card-body">
            <p>
              {{
                t(
                  "The event organiser has chosen to validate manually participations. Do you want to add a little note to explain why you want to participate to this event?"
                )
              }}
            </p>
            <form
              @submit.prevent="
                joinEvent(
                  actorForConfirmation as IPerson,
                  messageForConfirmation
                )
              "
            >
              <o-field :label="t('Message')">
                <o-input
                  type="textarea"
                  size="medium"
                  v-model="messageForConfirmation"
                  minlength="10"
                ></o-input>
              </o-field>
              <div class="buttons">
                <o-button
                  native-type="button"
                  class="button"
                  ref="cancelButton"
                  @click="isJoinConfirmationModalActive = false"
                  @keyup.enter="isJoinConfirmationModalActive = false"
                  >{{ t("Cancel") }}
                </o-button>
                <o-button variant="primary" native-type="submit">
                  {{ t("Confirm my participation") }}
                </o-button>
              </div>
            </form>
          </section>
        </div>
      </o-modal>
      <o-modal
        v-model:active="showMap"
        :close-button-aria-label="t('Close')"
        class="map-modal"
        v-if="event?.physicalAddress?.geom"
        has-modal-card
        full-screen
        :can-cancel="['escape', 'outside']"
      >
        <template #default="props">
          <event-map
            :routingType="routingType ?? RoutingType.OPENSTREETMAP"
            :address="event.physicalAddress"
            @close="props.close"
          />
        </template>
      </o-modal>
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  MemberRole,
  ParticipantRole,
  RoutingType,
} from "@/types/enums";
import {
  EVENT_PERSON_PARTICIPATION,
  // EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
  FETCH_EVENT,
  JOIN_EVENT,
  LEAVE_EVENT,
} from "@/graphql/event";
import { IEvent } from "@/types/event.model";
import {
  displayName,
  IActor,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
import { GRAPHQL_API_ENDPOINT } from "@/api/_entrypoint";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import MultiCard from "@/components/Event/MultiCard.vue";
import ReportModal from "@/components/Report/ReportModal.vue";
import IdentityPicker from "@/views/Account/IdentityPicker.vue";
import ParticipationSection from "@/components/Participation/ParticipationSection.vue";
import RouteName from "@/router/name";
import CommentTree from "@/components/Comment/CommentTree.vue";
import "intersection-observer";
import {
  AnonymousParticipationNotFoundError,
  getLeaveTokenForParticipation,
  isParticipatingInThisEvent,
  removeAnonymousParticipation,
} from "@/services/AnonymousParticipationStorage";
import Tag from "@/components/TagElement.vue";
import EventMetadataSidebar from "@/components/Event/EventMetadataSidebar.vue";
import EventBanner from "@/components/Event/EventBanner.vue";
import PopoverActorCard from "@/components/Account/PopoverActorCard.vue";
import { IParticipant } from "@/types/participant.model";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { eventMetaDataList } from "@/services/EventMetadata";
import { useDeleteEvent, useFetchEvent } from "@/composition/apollo/event";
import {
  computed,
  onMounted,
  ref,
  watch,
  defineAsyncComponent,
  inject,
} from "vue";
import { useRoute, useRouter } from "vue-router";
import Earth from "vue-material-design-icons/Earth.vue";
import Link from "vue-material-design-icons/Link.vue";
import Flag from "vue-material-design-icons/Flag.vue";
import CalendarPlus from "vue-material-design-icons/CalendarPlus.vue";
import ContentDuplicate from "vue-material-design-icons/ContentDuplicate.vue";
import Delete from "vue-material-design-icons/Delete.vue";
import Pencil from "vue-material-design-icons/Pencil.vue";
import HelpCircleOutline from "vue-material-design-icons/HelpCircleOutline.vue";
import TicketConfirmationOutline from "vue-material-design-icons/TicketConfirmationOutline.vue";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useLoggedUser } from "@/composition/apollo/user";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  useAnonymousActorId,
  useAnonymousParticipationConfig,
  useAnonymousReportsConfig,
  useEventCategories,
  useRoutingType,
} from "@/composition/apollo/config";
import { useCreateReport } from "@/composition/apollo/report";
import Share from "vue-material-design-icons/Share.vue";
import { useI18n } from "vue-i18n";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLErrors } from "@/types/errors.model";
import { useHead } from "@vueuse/head";
import { Snackbar } from "@/plugins/snackbar";

const ShareEventModal = defineAsyncComponent(
  () => import("@/components/Event/ShareEventModal.vue")
);
/* eslint-disable @typescript-eslint/no-unused-vars */
const IntegrationTwitch = defineAsyncComponent(
  () => import("@/components/Event/Integrations/TwitchIntegration.vue")
);
const IntegrationPeertube = defineAsyncComponent(
  () => import("@/components/Event/Integrations/PeerTubeIntegration.vue")
);
const IntegrationYoutube = defineAsyncComponent(
  () => import("@/components/Event/Integrations/YouTubeIntegration.vue")
);
const IntegrationJitsiMeet = defineAsyncComponent(
  () => import("@/components/Event/Integrations/JitsiMeetIntegration.vue")
);
const IntegrationEtherpad = defineAsyncComponent(
  () => import("@/components/Event/Integrations/EtherpadIntegration.vue")
);
/* eslint-enable @typescript-eslint/no-unused-vars */
const EventMap = defineAsyncComponent(
  () => import("@/components/Event/EventMap.vue")
);

const props = defineProps<{
  uuid: string;
}>();

const { t } = useI18n({ useScope: "global" });

const {
  event,
  onError: onFetchEventError,
  loading: eventLoading,
} = useFetchEvent(props.uuid);
const eventId = computed(() => event.value?.id);
const { currentActor } = useCurrentActorClient();
const currentActorId = computed(() => currentActor.value?.id);
const { loggedUser } = useLoggedUser();
const {
  result: participationsResult,
  // subscribeToMore: subscribeToMoreParticipation,
} = useQuery<{ person: IPerson }>(
  EVENT_PERSON_PARTICIPATION,
  () => ({
    eventId: event.value?.id,
    actorId: currentActorId.value,
  }),
  () => ({
    enabled:
      currentActorId.value !== undefined &&
      currentActorId.value !== null &&
      eventId.value !== undefined,
  })
);

// subscribeToMoreParticipation(() => ({
//   document: EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
//   variables: {
//     eventId: eventId,
//     actorId: currentActorId,
//   },
// }));

const participations = computed(
  () => participationsResult.value?.person.participations?.elements ?? []
);

const { person } = usePersonStatusGroup(
  usernameWithDomain(event.value?.attributedTo)
);

const { anonymousReportsConfig } = useAnonymousReportsConfig();
const { anonymousActorId } = useAnonymousActorId();
const { eventCategories } = useEventCategories();

const { anonymousParticipationConfig } = useAnonymousParticipationConfig();
const { identities } = useCurrentUserIdentities();

// metaInfo() {
//   return {
//     // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//     // @ts-ignore
//     title: this.eventTitle,
//     meta: [
//       // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//       // @ts-ignore
//       { name: "description", content: this.eventDescription },
//     ],
//   };
// },

const identity = ref<IPerson | undefined | null>(null);

const reportModal = ref();
const oldParticipationRole = ref<string | undefined>(undefined);
const isReportModalActive = ref(false);
const isShareModalActive = ref(false);
const isJoinModalActive = ref(false);
const isJoinConfirmationModalActive = ref(false);

const observer = ref<IntersectionObserver | null>(null);
const commentsObserver = ref<Element | null>(null);

const loadComments = ref(false);

const anonymousParticipation = ref<boolean | null>(null);
const actorForConfirmation = ref<IPerson | null>(null);
const messageForConfirmation = ref("");

const eventTitle = computed((): undefined | string => {
  return event.value?.title;
});

const eventDescription = computed((): undefined | string => {
  return event.value?.description;
});

const route = useRoute();
const router = useRouter();

const eventDescriptionElement = ref<HTMLElement | null>(null);

onMounted(async () => {
  identity.value = currentActor.value;
  if (route.hash.includes("#comment-")) {
    loadComments.value = true;
  }

  try {
    if (window.isSecureContext) {
      anonymousParticipation.value = await anonymousParticipationConfirmed();
    }
  } catch (e) {
    if (e instanceof AnonymousParticipationNotFoundError) {
      anonymousParticipation.value = null;
    } else {
      console.error(e);
    }
  }

  observer.value = new IntersectionObserver(
    (entries) => {
      // eslint-disable-next-line no-restricted-syntax
      for (const entry of entries) {
        if (entry) {
          loadComments.value = entry.isIntersecting || loadComments.value;
        }
      }
    },
    {
      rootMargin: "-50px 0px -50px",
    }
  );
  if (commentsObserver.value) {
    observer.value.observe(commentsObserver.value);
  }

  watch(eventDescription, () => {
    if (!eventDescription.value) return;
    if (!eventDescriptionElement.value) return;

    eventDescriptionElement.value.addEventListener("click", ($event) => {
      // TODO: Find the right type for target
      let { target }: { target: any } = $event;
      while (target && target.tagName !== "A") target = target.parentNode;
      // handle only links that occur inside the component and do not reference external resources
      if (target && target.matches(".hashtag") && target.href) {
        // some sanity checks taken from vue-router:
        // https://github.com/vuejs/vue-router/blob/dev/src/components/link.js#L106
        const { altKey, ctrlKey, metaKey, shiftKey, button, defaultPrevented } =
          $event;
        // don't handle with control keys
        if (metaKey || altKey || ctrlKey || shiftKey) return;
        // don't handle when preventDefault called
        if (defaultPrevented) return;
        // don't handle right clicks
        if (button !== undefined && button !== 0) return;
        // don't handle if `target="_blank"`
        if (target && target.getAttribute) {
          const linkTarget = target.getAttribute("target");
          if (/\b_blank\b/i.test(linkTarget)) return;
        }
        // don't handle same page links/anchors
        const url = new URL(target.href);
        const to = url.pathname;
        if (window.location.pathname !== to && $event.preventDefault) {
          $event.preventDefault();
          router.push(to);
        }
      }
    });
  });

  // this.$on("event-deleted", () => {
  //   return router.push({ name: RouteName.HOME });
  // });
});

const deleteEventMessage = computed(() => {
  const participantsLength = event.value?.participantStats.participant;
  const prefix = participantsLength
    ? t(
        "There are {participants} participants.",
        {
          participants: event.value.participantStats.participant,
        },
        event.value.participantStats.participant
      )
    : "";
  return `${prefix}
        ${t(
          "Are you sure you want to delete this event? This action cannot be reverted."
        )}
        <br><br>
        ${t('To confirm, type your event title "{eventTitle}"', {
          eventTitle: event.value?.title,
        })}`;
});

const notifier = inject<Notifier>("notifier");
const dialog = inject<Dialog>("dialog");

const {
  mutate: deleteEvent,
  onDone: onDeleteEventDone,
  onError: onDeleteEventError,
} = useDeleteEvent();

const escapeRegExp = (string: string) => {
  return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); // $& means the whole matched string
};

const openDeleteEventModal = () => {
  dialog?.prompt({
    title: t("Delete event"),
    message: deleteEventMessage.value,
    confirmText: t("Delete event"),
    cancelText: t("Cancel"),
    variant: "danger",
    hasIcon: true,
    hasInput: true,
    inputAttrs: {
      placeholder: event.value?.title,
      pattern: escapeRegExp(event.value?.title ?? ""),
    },
    onConfirm: (result: string) => {
      console.debug("calling delete event", result);
      if (result.trim() === event.value?.title) {
        event.value?.id ? deleteEvent({ eventId: event.value?.id }) : null;
      }
    },
  });
};

onDeleteEventDone(() => {
  router.push({ name: RouteName.MY_EVENTS });
});

onDeleteEventError((error) => {
  console.error(error);
});

const {
  mutate: createReportMutation,
  onDone: onCreateReportDone,
  onError: onCreateReportError,
} = useCreateReport();

onCreateReportDone(() => {
  notifier?.success(t("Event {eventTitle} reported", { eventTitle }));
});

onCreateReportError((error) => {
  console.error(error);
});

const reportEvent = async (
  content: string,
  forward: boolean
): Promise<void> => {
  isReportModalActive.value = false;
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  reportModal.value.close();
  if (!organizer.value) return;

  createReportMutation({
    eventId: event.value?.id ?? "",
    reportedId: organizer.value?.id ?? "",
    content,
    forward,
  });
};

const joinEventWithConfirmation = (actor: IPerson): void => {
  isJoinConfirmationModalActive.value = true;
  actorForConfirmation.value = actor;
};

const {
  mutate: joinEventMutation,
  onDone: onJoinEventMutationDone,
  onError: onJoinEventMutationError,
} = useMutation<{
  joinEvent: IParticipant;
}>(JOIN_EVENT, () => ({
  update: (
    store: ApolloCache<{
      joinEvent: IParticipant;
    }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;

    const participationCachedData = store.readQuery<{ person: IPerson }>({
      query: EVENT_PERSON_PARTICIPATION,
      variables: { eventId: event.value?.id, actorId: identity.value?.id },
    });

    if (participationCachedData?.person == undefined) {
      console.error(
        "Cannot update participation cache, because of null value."
      );
      return;
    }
    store.writeQuery({
      query: EVENT_PERSON_PARTICIPATION,
      variables: { eventId: event.value?.id, actorId: identity.value?.id },
      data: {
        person: {
          ...participationCachedData?.person,
          participations: {
            elements: [data.joinEvent],
            total: 1,
          },
        },
      },
    });

    const cachedData = store.readQuery<{ event: IEvent }>({
      query: FETCH_EVENT,
      variables: { uuid: event.value?.uuid },
    });
    if (cachedData == null) return;
    const { event: cachedEvent } = cachedData;
    if (cachedEvent === null) {
      console.error(
        "Cannot update event participant cache, because of null value."
      );
      return;
    }
    const participantStats = { ...cachedEvent.participantStats };

    if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
      participantStats.notApproved += 1;
    } else {
      participantStats.going += 1;
      participantStats.participant += 1;
    }

    store.writeQuery({
      query: FETCH_EVENT,
      variables: { uuid: props.uuid },
      data: {
        event: {
          ...cachedEvent,
          participantStats,
        },
      },
    });
  },
}));

const joinEvent = async (
  identityForJoin: IPerson,
  message: string | null = null
): Promise<void> => {
  isJoinConfirmationModalActive.value = false;
  isJoinModalActive.value = false;
  joinEventMutation({
    eventId: event.value?.id,
    actorId: identityForJoin?.id,
    message,
  });
};

onJoinEventMutationDone(({ data }) => {
  if (data) {
    if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
      participationRequestedMessage();
    } else {
      participationConfirmedMessage();
    }
  }
});

onJoinEventMutationError((error) => {
  console.error(error);
});

const confirmLeave = (): void => {
  dialog?.confirm({
    title: t('Leaving event "{title}"', {
      title: event.value?.title,
    }),
    message: t(
      'Are you sure you want to cancel your participation at event "{title}"?',
      {
        title: event.value?.title,
      }
    ),
    confirmText: t("Leave event"),
    cancelText: t("Cancel"),
    variant: "danger",
    hasIcon: true,
    onConfirm: () => {
      if (event.value && currentActor.value?.id) {
        console.debug("calling leave event");
        leaveEvent(event.value, currentActor.value.id);
      }
    },
  });
};

watch(participations, () => {
  if (participations.value.length > 0) {
    if (
      oldParticipationRole.value &&
      participations.value[0].role !== ParticipantRole.NOT_APPROVED &&
      oldParticipationRole.value !== participations.value[0].role
    ) {
      switch (participations.value[0].role) {
        case ParticipantRole.PARTICIPANT:
          participationConfirmedMessage();
          break;
        case ParticipantRole.REJECTED:
          participationRejectedMessage();
          break;
        default:
          participationChangedMessage();
          break;
      }
    }
    oldParticipationRole.value = participations.value[0].role;
  }
});

const participationConfirmedMessage = () => {
  notifier?.success(t("Your participation has been confirmed"));
};

const participationRequestedMessage = () => {
  notifier?.success(t("Your participation has been requested"));
};

const participationRejectedMessage = () => {
  notifier?.error(t("Your participation has been rejected"));
};

const participationChangedMessage = () => {
  notifier?.info(t("Your participation status has been changed"));
};

const downloadIcsEvent = async (): Promise<void> => {
  const data = await (
    await fetch(`${GRAPHQL_API_ENDPOINT}/events/${props.uuid}/export/ics`)
  ).text();
  const blob = new Blob([data], { type: "text/calendar" });
  const link = document.createElement("a");
  link.href = window.URL.createObjectURL(blob);
  link.download = `${event.value?.title}.ics`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

const triggerShare = (): void => {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore-start
  if (navigator.share) {
    navigator
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      .share({
        title: event.value?.title,
        url: event.value?.url,
      })
      .then(() => console.debug("Successful share"))
      .catch((error: any) => console.debug("Error sharing", error));
  } else {
    isShareModalActive.value = true;
    // send popup
  }
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore-end
};

const handleErrors = (errors: AbsintheGraphQLErrors): void => {
  if (
    errors.some((error) => error.status_code === 404) ||
    errors.some(({ message }) => message.includes("has invalid value $uuid"))
  ) {
    router.replace({ name: RouteName.PAGE_NOT_FOUND });
  }
};

onFetchEventError(({ graphQLErrors }) =>
  handleErrors(graphQLErrors as AbsintheGraphQLErrors)
);

// const actorIsParticipant = computed((): boolean => {
//   if (actorIsOrganizer.value) return true;

//   return (
//     participations.value.length > 0 &&
//     participations.value[0].role === ParticipantRole.PARTICIPANT
//   );
// });

const actorIsOrganizer = computed((): boolean => {
  return (
    participations.value.length > 0 &&
    participations.value[0].role === ParticipantRole.CREATOR
  );
});

const hasGroupPrivileges = computed((): boolean => {
  return (
    person.value?.memberships !== undefined &&
    person.value?.memberships?.total > 0 &&
    [MemberRole.MODERATOR, MemberRole.ADMINISTRATOR].includes(
      person.value?.memberships?.elements[0].role
    )
  );
});

const canManageEvent = computed((): boolean => {
  return actorIsOrganizer.value || hasGroupPrivileges.value;
});

// const endDate = computed((): string | undefined => {
//   return event.value?.endsOn && event.value.endsOn > event.value.beginsOn
//     ? event.value.endsOn
//     : event.value?.beginsOn;
// });

const maximumAttendeeCapacity = computed((): number | undefined => {
  return event.value?.options?.maximumAttendeeCapacity;
});

const eventCapacityOK = computed((): boolean => {
  if (event.value?.draft) return true;
  if (!maximumAttendeeCapacity.value) return true;
  return (
    event.value?.options?.maximumAttendeeCapacity !== undefined &&
    event.value.participantStats.participant !== undefined &&
    event.value?.options?.maximumAttendeeCapacity >
      event.value.participantStats.participant
  );
});

// const numberOfPlacesStillAvailable = computed((): number | undefined => {
//   if (event.value?.draft) return maximumAttendeeCapacity.value;
//   return (
//     (maximumAttendeeCapacity.value ?? 0) -
//     (event.value?.participantStats.participant ?? 0)
//   );
// });

const anonymousParticipationConfirmed = async (): Promise<boolean> => {
  return isParticipatingInThisEvent(props.uuid);
};

const cancelAnonymousParticipation = async (): Promise<void> => {
  if (!event.value || !anonymousActorId.value) return;
  const token = (await getLeaveTokenForParticipation(props.uuid)) as string;
  leaveEvent(event.value, anonymousActorId.value, token);
  await removeAnonymousParticipation(props.uuid);
  anonymousParticipation.value = null;
};

const ableToReport = computed((): boolean => {
  return (
    currentActor.value?.id != null ||
    anonymousReportsConfig.value?.allowed === true
  );
});

const organizer = computed((): IActor | null => {
  if (event.value?.attributedTo?.id) {
    return event.value.attributedTo;
  }
  if (event.value?.organizerActor) {
    return event.value.organizerActor;
  }
  return null;
});

const organizerDomain = computed((): string | undefined => {
  return organizer.value?.domain ?? undefined;
});

const metadataToComponent: Record<string, string> = {
  "mz:live:twitch:url": "IntegrationTwitch",
  "mz:live:peertube:url": "IntegrationPeertube",
  "mz:live:youtube:url": "IntegrationYoutube",
  "mz:visio:jitsi_meet": "IntegrationJitsiMeet",
  "mz:notes:etherpad:url": "IntegrationEtherpad",
};

const integrations = computed((): Record<string, IEventMetadataDescription> => {
  return (event.value?.metadata ?? [])
    .map((val) => {
      const def = eventMetaDataList.find((dat) => dat.key === val.key);
      return {
        ...def,
        ...val,
      };
    })
    .reduce((acc: Record<string, IEventMetadataDescription>, metadata) => {
      const component = metadataToComponent[metadata.key];
      if (component !== undefined) {
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        acc[component] = metadata;
      }
      return acc;
    }, {});
});

const showMap = ref(false);

const { routingType } = useRoutingType();

const eventCategory = computed((): string | undefined => {
  if (event.value?.category === "MEETING") {
    return undefined;
  }
  return (eventCategories.value ?? []).find((eventCategoryToFind) => {
    return eventCategoryToFind.id === event.value?.category;
  })?.label as string;
});

const {
  mutate: leaveEventMutation,
  onDone: onLeaveEventMutationDone,
  onError: onLeaveEventMutationError,
} = useMutation<{ leaveEvent: { actor: { id: string } } }>(LEAVE_EVENT, () => ({
  update: (
    store: ApolloCache<{
      leaveEvent: IParticipant;
    }>,
    { data }: FetchResult,
    { context, variables }
  ) => {
    if (data == null) return;
    let participation;

    const token = context?.token;
    const actorId = variables?.actorId;
    const localEventId = variables?.eventId;
    const eventUUID = context?.eventUUID;
    const isAnonymousParticipationConfirmed =
      context?.isAnonymousParticipationConfirmed;

    if (!token) {
      const participationCachedData = store.readQuery<{
        person: IPerson;
      }>({
        query: EVENT_PERSON_PARTICIPATION,
        variables: { eventId: localEventId, actorId },
      });
      if (participationCachedData == null) return;
      const { person: cachedPerson } = participationCachedData;
      [participation] = cachedPerson?.participations?.elements ?? [undefined];

      store.modify({
        id: `Person:${actorId}`,
        fields: {
          participations() {
            return {
              elements: [],
              total: 0,
            };
          },
        },
      });
    }

    const eventCachedData = store.readQuery<{ event: IEvent }>({
      query: FETCH_EVENT,
      variables: { uuid: eventUUID },
    });
    if (eventCachedData == null) return;
    const { event: eventCached } = eventCachedData;
    if (eventCached === null) {
      console.error("Cannot update event cache, because of null value.");
      return;
    }
    const participantStats = { ...eventCached.participantStats };
    if (participation && participation?.role === ParticipantRole.NOT_APPROVED) {
      participantStats.notApproved -= 1;
    } else if (isAnonymousParticipationConfirmed === false) {
      participantStats.notConfirmed -= 1;
    } else {
      participantStats.going -= 1;
      participantStats.participant -= 1;
    }
    store.writeQuery({
      query: FETCH_EVENT,
      variables: { uuid: eventUUID },
      data: {
        event: {
          ...eventCached,
          participantStats,
        },
      },
    });
  },
}));

const leaveEvent = (
  eventToLeave: IEvent,
  actorId: string,
  token: string | null = null,
  isAnonymousParticipationConfirmed: boolean | null = null
): void => {
  leaveEventMutation(
    {
      eventId: eventToLeave.id,
      actorId,
      token,
    },
    {
      context: {
        token,
        isAnonymousParticipationConfirmed,
        eventUUID: eventToLeave.uuid,
      },
    }
  );
};

onLeaveEventMutationDone(({ data }) => {
  if (data) {
    notifier?.success(t("You have cancelled your participation"));
  }
});

const snackbar = inject<Snackbar>("snackbar");

onLeaveEventMutationError((error) => {
  snackbar?.open({
    message: error.message,
    variant: "danger",
    position: "bottom",
  });
  console.error(error);
});

useHead({
  title: computed(() => eventTitle.value ?? ""),
  meta: [{ name: "description", content: eventDescription.value }],
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.section {
  padding: 1rem 2rem 4rem;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}

div.sidebar {
  display: flex;
  flex-wrap: wrap;
  flex-direction: column;

  position: relative;

  &::before {
    content: "";
    background: #b3b3b2;
    position: absolute;
    bottom: 30px;
    top: 30px;
    left: 0;
    height: calc(100% - 60px);
    width: 1px;
  }

  div.organizer {
    display: inline-flex;
    padding-top: 10px;

    a {
      color: #4a4a4a;

      span {
        line-height: 2.7rem;
        @include padding-right(6px);
      }
    }
  }
}

.intro {
  // background: white;

  .is-3-tablet {
    width: initial;
  }

  p.tags {
    a {
      text-decoration: none;
    }

    span {
      &.tag {
        margin: 0 2px;
      }
    }
  }
}

.event-description-wrapper {
  padding: 0;

  aside.event-metadata {
    min-width: 20rem;
    flex: 1;

    .sticky {
      // position: sticky;
      // background: white;
      top: 50px;
      padding: 1rem;
    }
  }

  div.event-description-comments {
    min-width: 20rem;
    padding: 1rem;
    flex: 2;
    // background: white;
  }

  .description-content {
    :deep(h1) {
      font-size: 2rem;
    }

    :deep(h2) {
      font-size: 1.5rem;
    }

    :deep(h3) {
      font-size: 1.25rem;
    }

    :deep(ul) {
      list-style-type: disc;
    }

    :deep(li) {
      margin: 10px auto 10px 2rem;
    }

    :deep(blockquote) {
      border-left: 0.2em solid #333;
      display: block;
      @include padding-left(1rem);
    }

    :deep(p) {
      margin: 10px auto;

      a {
        display: inline-block;
        padding: 0.3rem;
        color: #111;

        &:empty {
          display: none;
        }
      }
    }
  }
}

.comments {
  padding-top: 3rem;

  a h3#comments {
    margin-bottom: 10px;
  }
}

.more-events {
  // background: white;
  padding: 1rem 1rem 4rem;

  & > .title {
    font-size: 1.5rem;
  }
}

// .dropdown .dropdown-trigger span {
//   cursor: pointer;
// }

// a.dropdown-item,
// .dropdown .dropdown-menu .has-link a,
// button.dropdown-item {
//   white-space: nowrap;
//   width: 100%;
//   @include padding-right(1rem);
//   text-align: right;
// }

a.participations-link {
  text-decoration: none;
}

.no-border {
  border: 0;
  cursor: auto;
}

.wrapper,
.intro-wrapper {
  display: flex;
  flex-direction: column;
}

.intro-wrapper {
  position: relative;
  padding: 0 16px 16px;
  // background: #fff;

  .date-calendar-icon-wrapper {
    margin-top: 16px;
    height: 0;
    display: flex;
    align-items: flex-end;
    align-self: flex-start;
    margin-bottom: 7px;
    @include margin-left(0);
  }
}
.title {
  margin: 0;
  font-size: 2rem;
}
</style>
