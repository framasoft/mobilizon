<template>
  <div class="" style="display: flex; gap: 0.5rem; justify-content: center">
    <external-participation-button
      v-if="event && event.joinOptions === EventJoinOptions.EXTERNAL"
      :event="event"
      :current-actor="currentActor"
    />

    <participation-section
      v-else-if="event && anonymousParticipationConfig"
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

    <o-button
      outlined
      icon-right="share"
      @click="triggerShare()"
      @keyup.enter="triggerShare()"
    >
      {{ t("Share") }}
    </o-button>

    <o-button
      icon-right="CalendarPlus"
      outlined
      @click="downloadIcsEvent()"
      @keyup.enter="downloadIcsEvent()"
    >
      {{ t("Speichern") }}
    </o-button>
  </div>

  <o-modal
    v-model:active="isReportModalActive"
    has-modal-card
    ref="reportModal"
    :close-button-aria-label="t('Close')"
    :autoFocus="false"
    :trapFocus="false"
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
            joinEvent(actorForConfirmation as IPerson, messageForConfirmation)
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
</template>

<script lang="ts" setup>
import { IActor, IPerson } from "@/types/actor";
import { IEvent } from "@/types/event.model";
import ParticipationSection from "@/components/Participation/ParticipationSection.vue";
import ReportModal from "@/components/Report/ReportModal.vue";
import IdentityPicker from "@/components/Account/IdentityPicker.vue";
import { EventJoinOptions, ParticipantRole } from "@/types/enums";
import { GRAPHQL_API_ENDPOINT } from "@/api/_entrypoint";
import { computed, defineAsyncComponent, inject, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import {
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
  JOIN_EVENT,
  LEAVE_EVENT,
} from "@/graphql/event";
import { Notifier } from "@/plugins/notifier";
import { Dialog } from "@/plugins/dialog";
import { Snackbar } from "@/plugins/snackbar";
import RouteName from "@/router/name";
import {
  AnonymousParticipationNotFoundError,
  getLeaveTokenForParticipation,
  isParticipatingInThisEvent,
  removeAnonymousParticipation,
} from "@/services/AnonymousParticipationStorage";
import {
  useAnonymousActorId,
  useAnonymousParticipationConfig,
} from "@/composition/apollo/config";
import { useCurrentUserIdentities } from "@/composition/apollo/actor";
import { useRouter } from "vue-router";
import { IParticipant } from "@/types/participant.model";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { useMutation } from "@vue/apollo-composable";
import { useCreateReport } from "@/composition/apollo/report";
import { useOruga } from "@oruga-ui/oruga-next";
import ExternalParticipationButton from "./ExternalParticipationButton.vue";

const ShareEventModal = defineAsyncComponent(
  () => import("@/components/Event/ShareEventModal.vue")
);

const props = defineProps<{
  event: IEvent;
  currentActor: IPerson | undefined;
  participations: IParticipant[];
  person: IPerson | undefined;
}>();

const { t } = useI18n({ useScope: "global" });

const notifier = inject<Notifier>("notifier");
const dialog = inject<Dialog>("dialog");

const router = useRouter();

const { anonymousActorId } = useAnonymousActorId();
const { anonymousParticipationConfig } = useAnonymousParticipationConfig();
const { identities } = useCurrentUserIdentities();

const event = computed(() => props.event);

const identity = ref<IPerson | undefined | null>(null);

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

const reportModal = ref();
const isReportModalActive = ref(false);
const isShareModalActive = ref(false);
const isJoinModalActive = ref(false);
const isJoinConfirmationModalActive = ref(false);

const actorForConfirmation = ref<IPerson | null>(null);
const messageForConfirmation = ref("");

const anonymousParticipation = ref<boolean | null>(null);

const downloadIcsEvent = async (): Promise<void> => {
  const data = await (
    await fetch(`${GRAPHQL_API_ENDPOINT}/events/${event.value.uuid}/export/ics`)
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

// const actorIsParticipant = computed((): boolean => {
//   if (actorIsOrganizer.value) return true;

//   return (
//     participations.value.length > 0 &&
//     participations.value[0].role === ParticipantRole.PARTICIPANT
//   );
// });

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
      variables: { uuid: props.event.uuid },
      data: {
        event: {
          ...cachedEvent,
          participantStats,
        },
      },
    });
  },
}));

const joinEvent = (
  identityForJoin: IPerson,
  message: string | null = null
): void => {
  isJoinConfirmationModalActive.value = false;
  isJoinModalActive.value = false;
  joinEventMutation({
    eventId: event.value?.id,
    actorId: identityForJoin?.id,
    message,
  });
};

const participationRequestedMessage = () => {
  notifier?.success(t("Your participation has been requested"));
};

const participationConfirmedMessage = () => {
  notifier?.success(t("Your participation has been confirmed"));
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

const { notification } = useOruga();

onJoinEventMutationError((error) => {
  if (error.message) {
    notification.open({
      message: error.message,
      variant: "danger",
      position: "bottom-right",
      duration: 5000,
    });
  }
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
      if (event.value && props.currentActor?.id) {
        console.debug("calling leave event");
        leaveEvent(event.value, props.currentActor.id);
      }
    },
  });
};

const {
  mutate: createReportMutation,
  onDone: onCreateReportDone,
  onError: onCreateReportError,
} = useCreateReport();

onCreateReportDone(() => {
  notifier?.success(
    t("Event {eventTitle} reported", { eventTitle: props?.event?.title })
  );
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
    eventsIds: [event.value?.id ?? ""],
    reportedId: organizer.value?.id ?? "",
    content,
    forward,
  });
};

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

const anonymousParticipationConfirmed = async (): Promise<boolean> => {
  return isParticipatingInThisEvent(props.event?.uuid);
};

const cancelAnonymousParticipation = async (): Promise<void> => {
  if (!event.value || !anonymousActorId.value) return;
  const token = (await getLeaveTokenForParticipation(
    props.event?.uuid
  )) as string;
  leaveEvent(event.value, anonymousActorId.value, token);
  await removeAnonymousParticipation(props.event?.uuid);
  anonymousParticipation.value = null;
};

onMounted(async () => {
  identity.value = props.currentActor;

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
});

onDeleteEventDone(() => {
  router.push({ name: RouteName.MY_EVENTS });
});

onDeleteEventError((error) => {
  console.error(error);
});
</script>
