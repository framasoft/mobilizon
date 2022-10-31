<template>
  <article
    class="bg-white dark:bg-zinc-700 dark:text-white dark:hover:text-white rounded-lg shadow-md max-w-3xl p-2"
  >
    <div class="flex gap-2">
      <div class="">
        <date-calendar-icon :date="event.beginsOn.toString()" :small="true" />
      </div>
      <router-link
        :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
      >
        <h2 class="mt-0 line-clamp-2">{{ event.title }}</h2>
      </router-link>
    </div>
    <div class="">
      <span v-if="event.physicalAddress && event.physicalAddress.locality">
        {{ event.physicalAddress.locality }}
      </span>
      <span v-if="event.attributedTo">
        {{
          $t("Created by {name}", {
            name: displayName(event.attributedTo),
          })
        }}
      </span>
      <span v-else>
        {{
          $t("Organized by {name}", {
            name: displayName(event.organizerActor),
          })
        }}
      </span>
    </div>
    <div class="flex gap-1">
      <span>
        <Earth v-if="event.visibility === EventVisibility.PUBLIC" />
        <Link v-if="event.visibility === EventVisibility.UNLISTED" />
        <Lock v-if="event.visibility === EventVisibility.PRIVATE" />
      </span>
      <span>
        <span v-if="event.options.maximumAttendeeCapacity !== 0">
          {{
            $t("{approved} / {total} seats", {
              approved: event.participantStats.participant,
              total: event.options.maximumAttendeeCapacity,
            })
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
      </span>
    </div>
  </article>
</template>

<script lang="ts" setup>
import { IEventCardOptions, IEvent } from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import { displayName } from "@/types/actor";
import { EventVisibility } from "@/types/enums";
import RouteName from "../../router/name";
import Earth from "vue-material-design-icons/Earth.vue";
import Link from "vue-material-design-icons/Link.vue";
import Lock from "vue-material-design-icons/Lock.vue";

withDefaults(defineProps<{ event: IEvent; options?: IEventCardOptions }>(), {
  options: (): IEventCardOptions => ({
    hideDate: true,
    loggedPerson: false,
    hideDetails: false,
    organizerActor: null,
  }),
});
</script>
