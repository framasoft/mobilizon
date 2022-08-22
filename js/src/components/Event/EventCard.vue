<template>
  <router-link
    class="mbz-card max-w-xs shrink-0 w-[18rem] snap-center dark:bg-mbz-purple"
    :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
  >
    <div class="bg-secondary rounded-lg">
      <figure class="block relative pt-40">
        <lazy-image-wrapper
          :picture="event.picture"
          style="height: 100%; position: absolute; top: 0; left: 0; width: 100%"
        />
        <div
          class="absolute top-3 right-0 ltr:-mr-1 rtl:-ml-1 z-10 max-w-xs no-underline flex flex-col gap-1"
          v-if="event.tags || event.status !== EventStatus.CONFIRMED"
        >
          <mobilizon-tag
            variant="info"
            v-if="event.status === EventStatus.TENTATIVE"
          >
            {{ $t("Tentative") }}
          </mobilizon-tag>
          <mobilizon-tag
            variant="danger"
            v-if="event.status === EventStatus.CANCELLED"
          >
            {{ $t("Cancelled") }}
          </mobilizon-tag>
          <router-link
            :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
            v-for="tag in (event.tags || []).slice(0, 3)"
            :key="tag.slug"
          >
            <mobilizon-tag dir="auto">{{ tag.title }}</mobilizon-tag>
          </router-link>
        </div>
      </figure>
    </div>
    <div class="p-2">
      <div class="relative flex flex-col h-full">
        <div class="-mt-3 h-0 flex mb-3 ltr:ml-0 rtl:mr-0 items-end self-start">
          <date-calendar-icon
            :small="true"
            v-if="!mergedOptions.hideDate"
            :date="event.beginsOn.toString()"
          />
        </div>
        <div class="w-full flex flex-col justify-between">
          <h3
            class="text-lg leading-5 line-clamp-3 font-bold text-violet-3 dark:text-white"
            :title="event.title"
            dir="auto"
            :lang="event.language"
          >
            {{ event.title }}
          </h3>
          <div class="pt-3">
            <div
              class="flex items-center text-violet-3 dark:text-white"
              dir="auto"
            >
              <figure class="" v-if="actorAvatarURL">
                <img
                  class="rounded-xl"
                  :src="actorAvatarURL"
                  alt=""
                  width="24"
                  height="24"
                />
              </figure>
              <account-circle v-else />
              <span class="text-sm font-semibold ltr:pl-2 rtl:pr-2">
                {{ organizerDisplayName(event) }}
              </span>
            </div>
            <inline-address
              v-if="event.physicalAddress"
              :physical-address="event.physicalAddress"
            />
            <div
              class="flex items-center text-sm"
              dir="auto"
              v-else-if="event.options && event.options.isOnline"
            >
              <Video />
              <span class="ltr:pl-2 rtl:pr-2">{{ $t("Online") }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </router-link>
</template>

<script lang="ts" setup>
import {
  IEvent,
  IEventCardOptions,
  organizerDisplayName,
  organizerAvatarUrl,
} from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import { EventStatus } from "@/types/enums";
import RouteName from "../../router/name";
import InlineAddress from "@/components/Address/InlineAddress.vue";

import { computed } from "vue";
import MobilizonTag from "../Tag.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Video from "vue-material-design-icons/Video.vue";

const props = defineProps<{ event: IEvent; options?: IEventCardOptions }>();
const defaultOptions: IEventCardOptions = {
  hideDate: false,
  loggedPerson: false,
  hideDetails: false,
  organizerActor: null,
};

const mergedOptions = computed<IEventCardOptions>(() => ({
  ...defaultOptions,
  ...props.options,
}));

// const actor = computed<Actor>(() => {
//   return Object.assign(
//     new Person(),
//     props.event.organizerActor ?? mergedOptions.value.organizerActor
//   );
// });

const actorAvatarURL = computed<string | null>(() =>
  organizerAvatarUrl(props.event)
);
</script>
