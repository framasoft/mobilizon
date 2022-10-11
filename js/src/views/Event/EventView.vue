<template>
  <div class="container mx-auto">
    <o-loading v-model:active="eventLoading" />
    <div class="flex flex-col mb-3">
      <event-banner :picture="event?.picture" />
      <div class="intro-wrapper flex flex-col relative px-2 pb-2">
        <div class="date-calendar-icon-wrapper" v-if="event?.beginsOn">
          <date-calendar-icon :date="event.beginsOn.toString()" />
        </div>

        <section class="intro" dir="auto">
          <div class="flex flex-wrap gap-2">
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
        class="event-description-wrapper rounded-lg dark:border-violet-title flex flex-wrap flex-col md:flex-row-reverse"
      >
        <aside
          class="event-metadata rounded bg-white dark:bg-gray-600 shadow-md h-min"
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
import { EventStatus, ParticipantRole, RoutingType } from "@/types/enums";
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

// const endDate = computed((): string | undefined => {
//   return event.value?.endsOn && event.value.endsOn > event.value.beginsOn
//     ? event.value.endsOn
//     : event.value?.beginsOn;
// });

const organizer = computed((): IActor | null => {
  if (event.value?.attributedTo?.id) {
    return event.value.attributedTo;
  }
  if (event.value?.organizerActor) {
    return event.value.organizerActor;
  }
  return null;
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

.intro-wrapper {
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
