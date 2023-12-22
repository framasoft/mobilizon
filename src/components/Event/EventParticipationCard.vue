<template>
  <article
    class="bg-white dark:bg-mbz-purple dark:hover:bg-mbz-purple-400 mb-5 mt-4 pb-2 md:p-0 rounded-t-lg"
  >
    <div
      class="bg-mbz-yellow-alt-100 flex p-2 text-violet-title rounded-t-lg"
      dir="auto"
    >
      <figure
        class="image is-24x24 ltr:pr-1 rtl:pl-1"
        v-if="participation.actor.avatar"
      >
        <img
          class="rounded"
          :src="participation.actor.avatar.url"
          alt=""
          height="24"
          width="24"
        />
      </figure>
      <AccountCircle class="ltr:pr-1 rtl:pl-1" v-else />
      {{ displayNameAndUsername(participation.actor) }}
    </div>
    <div class="list-card flex flex-col relative">
      <div
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-x-1.5 md:gap-y-3 gapt-x-3"
      >
        <div class="mr-0 ml-0">
          <div class="h-40 relative w-full">
            <div class="flex absolute bottom-2 left-2 z-10">
              <date-calendar-icon
                :date="participation.event.beginsOn.toString()"
                :small="true"
              />
            </div>
            <router-link
              class="h-full"
              :to="{
                name: RouteName.EVENT,
                params: { uuid: participation.event.uuid },
              }"
            >
              <lazy-image-wrapper
                :rounded="true"
                :picture="participation.event.picture"
                style="
                  height: 100%;
                  position: absolute;
                  top: 0;
                  left: 0;
                  width: 100%;
                "
              />
            </router-link>
          </div>
        </div>
        <div class="list-card-content lg:col-span-4 flex-1 p-2">
          <div class="flex items-center pt-2" dir="auto">
            <Tag
              variant="info"
              class="mr-1 mb-1"
              size="medium"
              v-if="participation.event.status === EventStatus.TENTATIVE"
            >
              {{ t("Tentative") }}
            </Tag>
            <Tag
              variant="danger"
              class="mr-1 mb-1"
              size="medium"
              v-if="participation.event.status === EventStatus.CANCELLED"
            >
              {{ t("Cancelled") }}
            </Tag>
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: participation.event.uuid },
              }"
            >
              <h3
                class="line-clamp-3 font-bold mx-auto my-0 text-lg text-violet-title dark:text-white"
                :lang="participation.event.language"
              >
                {{ participation.event.title }}
              </h3>
            </router-link>
          </div>
          <inline-address
            v-if="participation.event.physicalAddress"
            :physical-address="participation.event.physicalAddress"
          />
          <div
            class="flex gap-1"
            v-else-if="
              participation.event.options &&
              participation.event.options.isOnline
            "
          >
            <Video />
            <span>{{ t("Online") }}</span>
          </div>
          <div class="flex gap-1">
            <figure class="" v-if="actorAvatarURL">
              <img
                class="rounded"
                :src="actorAvatarURL"
                alt=""
                width="24"
                height="24"
              />
            </figure>
            <AccountCircle v-else />
            <span>
              {{ organizerDisplayName(participation.event) }}
            </span>
          </div>
          <div class="flex">
            <AccountGroup :class="{ 'has-text-danger': lastSeatsLeft }" />
            <span
              class="flex items-center py-0 px-2"
              v-if="participation.role !== ParticipantRole.NOT_APPROVED"
            >
              <!-- Less than 10 seats left -->
              <span class="has-text-danger" v-if="lastSeatsLeft">
                {{
                  t("{number} seats left", {
                    number: seatsLeft,
                  })
                }}
              </span>
              <span
                v-else-if="
                  participation.event.options.maximumAttendeeCapacity !== 0
                "
              >
                {{
                  t(
                    "{available}/{capacity} available places",
                    {
                      available:
                        participation.event.options.maximumAttendeeCapacity -
                        participation.event.participantStats.participant,
                      capacity:
                        participation.event.options.maximumAttendeeCapacity,
                    },
                    participation.event.options.maximumAttendeeCapacity -
                      participation.event.participantStats.participant
                  )
                }}
              </span>
              <span v-else>
                {{
                  t(
                    "{count} participants",
                    {
                      count: participation.event.participantStats.participant,
                    },
                    participation.event.participantStats.participant
                  )
                }}
              </span>
              <o-button
                v-if="participation.event.participantStats.notApproved > 0"
                variant="text"
                @click="
                  gotToWithCheck(participation, {
                    name: RouteName.PARTICIPATIONS,
                    query: { role: ParticipantRole.NOT_APPROVED },
                    params: { eventId: participation.event.uuid },
                  })
                "
              >
                {{
                  t(
                    "{count} requests waiting",
                    {
                      count: participation.event.participantStats.notApproved,
                    },
                    participation.event.participantStats.notApproved
                  )
                }}
              </o-button>
            </span>
          </div>
        </div>

        <o-dropdown
          aria-role="list"
          class="text-center self-center md:col-span-2 lg:col-span-1"
        >
          <template #trigger>
            <o-button icon-right="dots-horizontal">
              {{ t("Actions") }}
            </o-button>
          </template>
          <o-dropdown-item
            aria-role="listitem"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
          >
            <div
              class="flex gap-1"
              @click="
                gotToWithCheck(participation, {
                  name: RouteName.EDIT_EVENT,
                  params: { eventId: participation.event.uuid },
                })
              "
            >
              <Pencil />
              {{ t("Edit") }}
            </div>
          </o-dropdown-item>

          <o-dropdown-item
            aria-role="listitem"
            v-if="participation.role === ParticipantRole.CREATOR"
          >
            <div
              class="flex gap-1"
              @click="
                gotToWithCheck(participation, {
                  name: RouteName.DUPLICATE_EVENT,
                  params: { eventId: participation.event.uuid },
                })
              "
            >
              <ContentDuplicate />
              {{ t("Duplicate") }}
            </div>
          </o-dropdown-item>

          <o-dropdown-item
            aria-role="listitem"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
          >
            <div @click="openDeleteEventModalWrapper" class="flex gap-1">
              <Delete />
              {{ t("Delete") }}
            </div>
          </o-dropdown-item>

          <o-dropdown-item
            aria-role="listitem"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
          >
            <div
              class="flex gap-1"
              @click="
                gotToWithCheck(participation, {
                  name: RouteName.PARTICIPATIONS,
                  params: { eventId: participation.event.uuid },
                })
              "
            >
              <AccountMultiplePlus />
              {{ t("Manage participations") }}
            </div>
          </o-dropdown-item>

          <o-dropdown-item
            aria-role="listitem"
            has-link
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
          >
            <router-link
              class="flex gap-1"
              :to="{
                name: RouteName.ANNOUNCEMENTS,
                params: { eventId: participation.event?.uuid },
              }"
            >
              <Bullhorn />
              {{ t("Announcements") }}
            </router-link>
          </o-dropdown-item>

          <o-dropdown-item aria-role="listitem">
            <router-link
              class="flex gap-1"
              :to="{
                name: RouteName.EVENT,
                params: { uuid: participation.event.uuid },
              }"
            >
              <ViewCompact />
              {{ t("View event page") }}
            </router-link>
          </o-dropdown-item>
        </o-dropdown>
      </div>
    </div>
  </article>
</template>

<script lang="ts" setup>
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { EventStatus, ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import {
  IEvent,
  IEventCardOptions,
  organizerAvatarUrl,
  organizerDisplayName,
} from "@/types/event.model";
import { displayNameAndUsername, IPerson } from "@/types/actor";
import RouteName from "@/router/name";
import { changeIdentity } from "@/utils/identity";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import InlineAddress from "@/components/Address/InlineAddress.vue";
import { RouteLocationRaw, useRouter } from "vue-router";
import Pencil from "vue-material-design-icons/Pencil.vue";
import ContentDuplicate from "vue-material-design-icons/ContentDuplicate.vue";
import Delete from "vue-material-design-icons/Delete.vue";
import AccountMultiplePlus from "vue-material-design-icons/AccountMultiplePlus.vue";
import ViewCompact from "vue-material-design-icons/ViewCompact.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import Video from "vue-material-design-icons/Video.vue";
import { useOruga } from "@oruga-ui/oruga-next";
import { computed, inject } from "vue";
import { useI18n } from "vue-i18n";
import { Dialog } from "@/plugins/dialog";
import { Snackbar } from "@/plugins/snackbar";
import { useDeleteEvent } from "@/composition/apollo/event";
import Tag from "@/components/TagElement.vue";
import { escapeHtml } from "@/utils/html";
import Bullhorn from "vue-material-design-icons/Bullhorn.vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";

const props = defineProps<{
  participation: IParticipant;
  options?: IEventCardOptions;
}>();

const emit = defineEmits(["eventDeleted"]);

const { currentActor } = useCurrentActorClient();
const { t } = useI18n({ useScope: "global" });

const dialog = inject<Dialog>("dialog");

const openDeleteEventModal = (
  event: IEvent,
  callback: (anEvent: IEvent) => any
): void => {
  function escapeRegExp(string: string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); // $& means the whole matched string
  }
  const participantsLength = event.participantStats.participant;
  const prefix = participantsLength
    ? t(
        "There are {participants} participants.",
        {
          participants: participantsLength,
        },
        participantsLength
      )
    : "";

  dialog?.prompt({
    variant: "danger",
    title: t("Delete event"),
    message: `${prefix}
      ${t(
        "Are you sure you want to delete this event? This action cannot be reverted."
      )}
      <br><br>
      ${t('To confirm, type your event title "{eventTitle}"', {
        eventTitle: escapeHtml(event.title),
      })}`,
    confirmText: t("Delete {eventTitle}", {
      eventTitle: event.title,
    }),
    inputAttrs: {
      placeholder: event.title,
      pattern: escapeRegExp(event.title),
    },
    hasInput: true,
    onConfirm: () => callback(event),
  });
};

const { notification } = useOruga();
const snackbar = inject<Snackbar>("snackbar");

const {
  mutate: deleteEvent,
  onDone: onDeleteEventDone,
  onError: onDeleteEventError,
} = useDeleteEvent();

onDeleteEventDone(() => {
  /**
   * When the event corresponding has been deleted (by the organizer).
   * A notification is already triggered.
   *
   * @type {string}
   */
  emit("eventDeleted", props.participation.event.id);

  notification.open({
    message: t("Event {eventTitle} deleted", {
      eventTitle: props.participation.event.title,
    }),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
});

onDeleteEventError((error) => {
  snackbar?.open({
    message: error.message,
    variant: "danger",
    position: "bottom",
  });

  console.error(error);
});

/**
 * Delete the event
 */
const openDeleteEventModalWrapper = () => {
  openDeleteEventModal(props.participation.event, (event: IEvent) =>
    deleteEvent({ eventId: event.id ?? "" })
  );
};

const router = useRouter();

const gotToWithCheck = async (
  participation: IParticipant,
  route: RouteLocationRaw
): Promise<any> => {
  if (
    participation.actor.id !== currentActor.value?.id &&
    participation.event.organizerActor
  ) {
    const organizerActor = participation.event.organizerActor as IPerson;
    await changeIdentity(organizerActor);
    notification.open({
      message: t(
        "Current identity has been changed to {identityName} in order to manage this event.",
        {
          identityName: organizerActor.preferredUsername,
        }
      ),
      variant: "info",
      position: "bottom-right",
      duration: 5000,
    });
  }
  return router.push(route);
};

// const organizerActor = computed<IActor | undefined>(() => {
//   if (
//     props.participation.event.attributedTo &&
//     props.participation.event.attributedTo.id
//   ) {
//     return props.participation.event.attributedTo;
//   }
//   return props.participation.event.organizerActor;
// });

const seatsLeft = computed<number | null>(() => {
  if (props.participation.event.options.maximumAttendeeCapacity > 0) {
    return (
      props.participation.event.options.maximumAttendeeCapacity -
      props.participation.event.participantStats.participant
    );
  }
  return null;
});

const lastSeatsLeft = computed<boolean>(() => {
  if (seatsLeft.value) {
    return seatsLeft.value < 10;
  }
  return false;
});

const actorAvatarURL = computed<string | null>(() =>
  organizerAvatarUrl(props.participation.event)
);
</script>

<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

article.box {
  // div.tag-container {
  //   position: absolute;
  //   top: 10px;
  //   right: 0;
  //   @include margin-left(-5px);
  //   z-index: 10;
  //   max-width: 40%;

  //   span.tag {
  //     margin: 5px auto;
  //     box-shadow: 0 0 5px 0 rgba(0, 0, 0, 1);
  //     /*word-break: break-all;*/
  //     text-overflow: ellipsis;
  //     overflow: hidden;
  //     display: block;
  //     /*text-align: right;*/
  //     font-size: 1em;
  //     /*padding: 0 1px;*/
  //     line-height: 1.75em;
  //   }
  // }

  .list-card {
    // display: flex;
    // padding: 0 6px 0 0;
    // position: relative;
    // flex-direction: column;

    .content-and-actions {
      // display: grid;
      // grid-gap: 5px 10px;
      grid-template-areas: "preview" "body" "actions";

      // @include tablet {
      //   grid-template-columns: 1fr 3fr;
      //   grid-template-areas: "preview body" "actions actions";
      // }

      // @include desktop {
      //   grid-template-columns: 1fr 3fr 1fr;
      //   grid-template-areas: "preview body actions";
      // }

      .event-preview {
        grid-area: preview;

        & > div {
          height: 128px;
          // width: 100%;
          // position: relative;

          // div.date-component {
          //   display: flex;
          //   position: absolute;
          //   bottom: 5px;
          //   left: 5px;
          //   z-index: 1;
          // }

          // img {
          //   width: 100%;
          //   object-position: center;
          //   object-fit: cover;
          //   height: 100%;
          // }
        }
      }

      .actions {
        //   padding: 7px;
        //   cursor: pointer;
        //   align-self: center;
        //   justify-self: center;
        grid-area: actions;
      }

      div.list-card-content {
        // flex: 1;
        // padding: 5px;
        grid-area: body;

        // .participant-stats {
        //   display: flex;
        //   align-items: center;
        //   padding: 0 5px;
        // }

        // div.title-wrapper {
        //   display: flex;
        //   align-items: center;
        //   padding-top: 5px;

        //   a {
        //     text-decoration: none;
        //     padding-bottom: 5px;
        //   }

        //   .title {
        //     display: -webkit-box;
        //     -webkit-line-clamp: 3;
        //     -webkit-box-orient: vertical;
        //     overflow: hidden;
        //     font-size: 18px;
        //     line-height: 24px;
        //     margin: auto 0;
        //     font-weight: bold;
        //   }
        // }
      }
    }
  }

  // .identity-header {
  //   display: flex;
  //   padding: 5px;

  //   figure,
  //   span.icon {
  //     @include padding-right(3px);
  //   }
  // }

  // & > .columns {
  //   padding: 1.25rem;
  // }
  // padding: 0;
}
</style>
