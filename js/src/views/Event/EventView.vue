<template>
  <div class="container mx-auto">
    <o-loading v-model:active="eventLoading" />
    <div class="flex flex-col mb-3">
      <event-banner :picture="event?.picture" />
      <div
        class="flex flex-col relative pb-2 bg-white dark:bg-zinc-700 my-2 rounded"
      >
        <div class="date-calendar-icon-wrapper relative" v-if="event?.beginsOn">
          <date-calendar-icon
            :date="event.beginsOn.toString()"
            class="absolute left-3 -top-16"
          />
        </div>

        <section class="intro px-2 pt-4" dir="auto">
          <div class="flex flex-wrap gap-2">
            <div class="flex-1 min-w-[300px]">
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
              <div class="flex flex-wrap items-center gap-2 gap-y-4 mt-2 my-3">
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
                <template v-if="!event?.local && organizerDomain">
                  <a :href="event?.url">
                    <tag variant="info">{{ organizerDomain }}</tag>
                  </a>
                </template>
                <p class="flex flex-wrap gap-1 items-center" dir="auto">
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

            <EventActionSection
              v-if="event"
              :event="event"
              :currentActor="currentActor"
              :participations="participations"
              :person="person"
            />
          </div>
        </section>
      </div>

      <div
        class="rounded-lg dark:border-violet-title flex flex-wrap flex-col md:flex-row-reverse gap-4"
      >
        <aside
          class="rounded bg-white dark:bg-zinc-700 shadow-md h-min max-w-screen-sm"
        >
          <div class="sticky p-4">
            <event-metadata-sidebar
              v-if="event"
              :event="event"
              :user="loggedUser"
              @showMapModal="showMap = true"
            />
          </div>
        </aside>
        <div class="flex-1">
          <section
            class="event-description bg-white dark:bg-zinc-700 px-3 pt-1 pb-3 rounded mb-4"
          >
            <h2 class="text-2xl">{{ t("About this event") }}</h2>
            <p v-if="!event?.description">
              {{ t("The event organizer didn't add any description.") }}
            </p>
            <div v-else>
              <div
                :lang="event?.language"
                dir="auto"
                class="mt-4 prose md:prose-lg lg:prose-xl dark:prose-invert prose-h1:text-xl prose-h1:font-semibold prose-h2:text-lg prose-h3:text-base md:prose-h1:text-2xl md:prose-h1:font-semibold md:prose-h2:text-xl md:prose-h3:text-lg lg:prose-h1:text-2xl lg:prose-h1:font-semibold lg:prose-h2:text-xl lg:prose-h3:text-lg"
                ref="eventDescriptionElement"
                v-html="event.description"
              />
            </div>
          </section>
          <section class="my-4">
            <component
              v-for="(metadata, integration) in integrations"
              :is="metadataToComponent[integration]"
              :key="integration"
              :metadata="metadata"
              class="my-2"
            />
          </section>
          <section
            class="bg-white dark:bg-zinc-700 px-3 pt-1 pb-3 rounded my-4"
            ref="commentsObserver"
          >
            <a href="#comments">
              <h2 class="text-2xl" id="comments">{{ t("Comments") }}</h2>
            </a>
            <comment-tree v-if="event && loadComments" :event="event" />
          </section>
        </div>
      </div>

      <section
        class="bg-white dark:bg-zinc-700 px-3 pt-1 pb-3 rounded my-4"
        v-if="(event?.relatedEvents ?? []).length > 0"
      >
        <h2 class="text-2xl mb-2">
          {{ t("These events may interest you") }}
        </h2>
        <multi-card :events="event?.relatedEvents ?? []" />
      </section>
      <o-modal
        v-model:active="showMap"
        :close-button-aria-label="t('Close')"
        class="map-modal"
        v-if="event?.physicalAddress?.geom"
        has-modal-card
        full-screen
        :can-cancel="['escape', 'outside']"
      >
        <template #default>
          <event-map
            :routingType="routingType ?? RoutingType.OPENSTREETMAP"
            :address="event.physicalAddress"
            @close="showMap = false"
          />
        </template>
      </o-modal>
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  EventStatus,
  ParticipantRole,
  RoutingType,
  EventVisibility,
} from "@/types/enums";
import {
  EVENT_PERSON_PARTICIPATION,
  // EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
} from "@/graphql/event";
import {
  displayName,
  IActor,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import Earth from "vue-material-design-icons/Earth.vue";
import Link from "vue-material-design-icons/Link.vue";
import MultiCard from "@/components/Event/MultiCard.vue";
import RouteName from "@/router/name";
import CommentTree from "@/components/Comment/CommentTree.vue";
import "intersection-observer";
import Tag from "@/components/TagElement.vue";
import EventMetadataSidebar from "@/components/Event/EventMetadataSidebar.vue";
import EventBanner from "@/components/Event/EventBanner.vue";
import EventActionSection from "@/components/Event/EventActionSection.vue";
import PopoverActorCard from "@/components/Account/PopoverActorCard.vue";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { eventMetaDataList } from "@/services/EventMetadata";
import { useFetchEvent } from "@/composition/apollo/event";
import {
  computed,
  onMounted,
  ref,
  watch,
  defineAsyncComponent,
  inject,
} from "vue";
import { useRoute, useRouter } from "vue-router";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useLoggedUser } from "@/composition/apollo/user";
import { useQuery } from "@vue/apollo-composable";
import {
  useEventCategories,
  useRoutingType,
} from "@/composition/apollo/config";
import { useI18n } from "vue-i18n";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLErrors } from "@/types/errors.model";
import { useHead } from "@vueuse/head";

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
const EventMap = defineAsyncComponent(
  () => import("@/components/Event/EventMap.vue")
);

const props = defineProps<{
  uuid: string;
}>();

const { t } = useI18n({ useScope: "global" });

const propsUUID = computed(() => props.uuid)

const {
  event,
  onError: onFetchEventError,
  loading: eventLoading,
  refetch: refetchEvent,
} = useFetchEvent(props.uuid);

watch(propsUUID, (newUUid) => {
  refetchEvent({ uuid: newUUid })
})

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

const { eventCategories } = useEventCategories();

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

const oldParticipationRole = ref<string | undefined>(undefined);

const observer = ref<IntersectionObserver | null>(null);
const commentsObserver = ref<Element | null>(null);

const loadComments = ref(false);

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

const notifier = inject<Notifier>("notifier");

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

const participationRejectedMessage = () => {
  notifier?.error(t("Your participation has been rejected"));
};

const participationChangedMessage = () => {
  notifier?.info(t("Your participation status has been changed"));
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

const metadataToComponent: Record<string, any> = {
  "mz:live:twitch:url": IntegrationTwitch,
  "mz:live:peertube:url": IntegrationPeertube,
  "mz:live:youtube:url": IntegrationYoutube,
  "mz:visio:jitsi_meet": IntegrationJitsiMeet,
  "mz:notes:etherpad:url": IntegrationEtherpad,
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
        acc[metadata.key] = metadata;
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

useHead({
  title: computed(() => eventTitle.value ?? ""),
  meta: [{ name: "description", content: eventDescription.value }],
});
</script>
<style>
.event-description a {
  @apply inline-block p-1 bg-mbz-yellow-alt-200 text-black;
}
</style>
