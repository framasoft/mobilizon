<template>
  <router-link
    class="block md:flex gap-x-2 gap-y-3 bg-white dark:bg-violet-2 rounded-lg shadow-md w-full"
    dir="auto"
    :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
  >
    <div class="event-preview mr-0 ml-0">
      <div class="relative w-full">
        <div
          class="flex absolute bottom-2 left-2 z-10 date-component"
          :class="{
            'calendar-double': isDifferentBeginsEndsDate,
          }"
        >
          <date-calendar-icon :date="event.beginsOn.toString()" :small="true" />
          <MenuDown
            :small="true"
            class="left-3 relative"
            v-if="isDifferentBeginsEndsDate"
          />
          <date-calendar-icon
            :date="event.endsOn?.toString()"
            :small="true"
            v-if="isDifferentBeginsEndsDate"
          />
        </div>
        <lazy-image-wrapper
          :picture="event.picture"
          :rounded="true"
          class="object-cover flex-none h-40 md:w-48 rounded-t-lg md:rounded-none md:rounded-l-lg"
        />
      </div>
    </div>
    <div class="p-2">
      <h3
        class="pb-2 text-lg leading-6 line-clamp-3 font-bold text-violet-title dark:text-white"
        :lang="event.language"
        dir="auto"
      >
        <tag
          variant="info"
          class="mr-1"
          v-if="event.status === EventStatus.TENTATIVE"
        >
          {{ $t("Tentative") }}
        </tag>
        <tag
          variant="danger"
          class="mr-1"
          v-if="event.status === EventStatus.CANCELLED"
        >
          {{ $t("Cancelled") }}
        </tag>
        <tag
          class="mr-2 font-normal"
          variant="warning"
          size="medium"
          v-if="event.draft"
          >{{ $t("Draft") }}</tag
        >
        {{ event.title }}
      </h3>
      <inline-address
        v-if="event.physicalAddress"
        class=""
        :physical-address="event.physicalAddress"
      />
      <div class="" v-else-if="event.options && event.options.isOnline">
        <Video />
        <span>{{ $t("Online") }}</span>
      </div>
      <div class="flex gap-1" v-if="showOrganizer">
        <figure class="" v-if="organizer(event) && organizer(event)?.avatar">
          <img
            class="rounded-full"
            :src="organizer(event)?.avatar?.url"
            alt=""
            width="24"
            height="24"
          />
        </figure>
        <AccountCircle v-else :size="24" />
        <span class="">
          {{ organizerDisplayName(event) }}
        </span>
      </div>
      <p class="flex gap-1">
        <AccountMultiple />
        <span v-if="event.options.maximumAttendeeCapacity !== 0">
          {{
            $t(
              "{available}/{capacity} available places",
              {
                available:
                  event.options.maximumAttendeeCapacity -
                  event.participantStats.participant,
                capacity: event.options.maximumAttendeeCapacity,
              },
              event.options.maximumAttendeeCapacity -
                event.participantStats.participant
            )
          }}
        </span>
        <span v-else>
          {{
            $t(
              "{count} participants",
              {
                count: event.participantStats.participant,
              },
              event.participantStats.participant
            )
          }}
        </span>
        <span v-if="event.participantStats.notApproved > 0">
          <o-button
            variant="text"
            tag="router-link"
            :to="{
              name: RouteName.PARTICIPATIONS,
              query: { role: ParticipantRole.NOT_APPROVED },
              params: { eventId: event.uuid },
            }"
          >
            {{
              $t(
                "{count} requests waiting",

                {
                  count: event.participantStats.notApproved,
                },
                event.participantStats.notApproved
              )
            }}
          </o-button>
        </span>
      </p>
    </div>
  </router-link>
</template>
<script lang="ts" setup>
import { IEvent, organizer, organizerDisplayName } from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import MenuDown from "vue-material-design-icons/MenuDown.vue";
import { EventStatus, ParticipantRole } from "@/types/enums";
import RouteName from "../../router/name";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import InlineAddress from "@/components/Address/InlineAddress.vue";
import Video from "vue-material-design-icons/Video.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import Tag from "@/components/TagElement.vue";
import { computed, inject } from "vue";
import type { Locale } from "date-fns";
import { formatDateForEvent } from "@/utils/datetime";

const props = withDefaults(
  defineProps<{
    event: IEvent;
    showOrganizer?: boolean;
  }>(),
  { showOrganizer: false }
);

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const isDifferentBeginsEndsDate = computed(() => {
  if (!dateFnsLocale) return;
  const beginsOnStr = formatDateForEvent(
    new Date(props.event.beginsOn),
    dateFnsLocale
  );
  const endsOnStr = props.event.endsOn
    ? formatDateForEvent(new Date(props.event.endsOn), dateFnsLocale)
    : null;
  return endsOnStr && endsOnStr != beginsOnStr;
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

.calendar-double {
  display: block;
}

.event-minimalist-card-wrapper {
  // display: grid;
  // grid-gap: 5px 10px;
  grid-template-areas: "preview" "body";
  // color: initial;

  // @include desktop {
  grid-template-columns: 200px 3fr;
  grid-template-areas: "preview body";
  // }

  // .event-preview {
  //   & > div {
  //     position: relative;
  //     height: 120px;
  //     width: 100%;

  //     div.date-component {
  //       display: flex;
  //       position: absolute;
  //       bottom: 5px;
  //       left: 5px;
  //       z-index: 1;
  //     }
  //   }
  // }

  // .calendar-icon {
  //   @include margin-right(1rem);
  // }
}
</style>
