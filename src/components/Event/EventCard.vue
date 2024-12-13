<template>
  <LinkOrRouterLink
    class="mbz-card snap-center dark:bg-mbz-purple"
    :class="{
      'sm:flex sm:items-start': mode === 'row',
      'sm:max-w-xs w-[18rem] shrink-0 flex flex-col': mode === 'column',
    }"
    :to="to"
    :isInternal="isInternal"
  >
    <div
      class="rounded-lg"
      :class="{ 'sm:w-full sm:max-w-[20rem]': mode === 'row' }"
    >
      <div
        class="-mt-3 h-0 mb-3 ltr:ml-0 rtl:mr-0 block relative z-10"
        :class="{
          'sm:hidden': mode === 'row',
          'calendar-simple': !isDifferentBeginsEndsDate,
          'calendar-double': isDifferentBeginsEndsDate,
        }"
      >
        <date-calendar-icon
          :small="true"
          v-if="!mergedOptions.hideDate"
          :date="event.beginsOn.toString()"
        />
        <MenuDown
          :small="true"
          class="left-3 relative"
          v-if="!mergedOptions.hideDate && isDifferentBeginsEndsDate"
        />
        <date-calendar-icon
          :small="true"
          v-if="!mergedOptions.hideDate && isDifferentBeginsEndsDate"
          :date="event.endsOn?.toString()"
        />
      </div>

      <figure class="block relative pt-40">
        <lazy-image-wrapper
          :picture="event.picture"
          style="height: 100%; position: absolute; top: 0; left: 0; width: 100%"
        />
        <div
          class="absolute top-3 right-0 ltr:-mr-1 rtl:-ml-1 z-10 max-w-xs no-underline flex flex-col gap-1 items-end"
          v-show="mode === 'column'"
          v-if="event.tags || event.status !== EventStatus.CONFIRMED"
        >
          <mobilizon-tag
            variant="info"
            v-if="event.status === EventStatus.TENTATIVE"
          >
            {{ t("Tentative") }}
          </mobilizon-tag>
          <mobilizon-tag
            variant="danger"
            v-if="event.status === EventStatus.CANCELLED"
          >
            {{ t("Cancelled") }}
          </mobilizon-tag>
          <router-link
            :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
            v-for="tag in (event.tags || []).slice(0, 3)"
            :key="tag.slug"
          >
            <mobilizon-tag dir="auto" :with-hash-tag="true">{{
              tag.title
            }}</mobilizon-tag>
          </router-link>
        </div>
      </figure>
    </div>
    <div class="p-2 flex-auto" :class="{ 'sm:flex-1': mode === 'row' }">
      <div class="relative flex flex-col h-full">
        <div
          class="-mt-3 h-0 flex mb-3 ltr:ml-0 rtl:mr-0 items-end self-end"
          :class="{ 'sm:hidden': mode === 'row' }"
        >
          <start-time-icon
            :small="true"
            v-if="!mergedOptions.hideDate && event.options.showStartTime"
            :date="event.beginsOn.toString()"
            :timezone="event.options.timezone"
          />
        </div>
        <span
          class="text-gray-700 dark:text-white font-semibold hidden"
          :class="{ 'sm:block': mode === 'row' }"
          v-if="!isDifferentBeginsEndsDate"
          >{{ formatDateTimeWithCurrentLocale }}</span
        >
        <span
          class="text-gray-700 dark:text-white font-semibold hidden"
          :class="{ 'sm:block': mode === 'row' }"
          v-if="isDifferentBeginsEndsDate"
          >{{ formatBeginsOnDateWithCurrentLocale }}
          <ArrowRightThin :small="true" style="display: ruby" />
          {{ formatEndsOnDateWithCurrentLocale }}</span
        >
        <div class="w-full flex flex-col justify-between h-full">
          <h2
            class="mt-0 mb-2 text-2xl line-clamp-3 font-bold text-violet-3 dark:text-white"
            dir="auto"
            :lang="event.language"
          >
            {{ event.title }}
          </h2>
          <div class="">
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
                  loading="lazy"
                />
              </figure>
              <account-circle v-else />
              <span class="font-semibold ltr:pl-2 rtl:pr-2">
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
              <span class="ltr:pl-2 rtl:pr-2">{{ t("Online") }}</span>
            </div>
            <div
              class="mt-1 no-underline gap-1 items-center hidden"
              :class="{ 'sm:flex': mode === 'row' }"
              v-if="
                event.tags ||
                event.status !== EventStatus.CONFIRMED ||
                event.participantStats?.participant > 0
              "
            >
              <mobilizon-tag
                variant="info"
                v-if="event.participantStats?.participant > 0"
              >
                {{
                  t(
                    "{count} participants",
                    { count: event.participantStats?.participant },
                    event.participantStats?.participant
                  )
                }}
              </mobilizon-tag>
              <mobilizon-tag
                variant="info"
                v-if="event.status === EventStatus.TENTATIVE"
              >
                {{ t("Tentative") }}
              </mobilizon-tag>
              <mobilizon-tag
                variant="danger"
                v-if="event.status === EventStatus.CANCELLED"
              >
                {{ t("Cancelled") }}
              </mobilizon-tag>
              <router-link
                :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
                v-for="tag in (event.tags || []).slice(0, 3)"
                :key="tag.slug"
              >
                <mobilizon-tag :with-hash-tag="true" dir="auto">{{
                  tag.title
                }}</mobilizon-tag>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </LinkOrRouterLink>
</template>
<style scoped>
.calendar-simple {
  bottom: -117px;
  left: 5px;
}
.calendar-double {
  bottom: -45px;
  left: 5px;
}
</style>

<script lang="ts" setup>
import {
  IEvent,
  IEventCardOptions,
  organizerDisplayName,
  organizerAvatarUrl,
} from "@/types/event.model";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import StartTimeIcon from "@/components/Event/StartTimeIcon.vue";
import ArrowRightThin from "vue-material-design-icons/ArrowRightThin.vue";
import MenuDown from "vue-material-design-icons/MenuDown.vue";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import { EventStatus } from "@/types/enums";
import RouteName from "../../router/name";
import InlineAddress from "@/components/Address/InlineAddress.vue";

import { computed, inject } from "vue";
import MobilizonTag from "@/components/TagElement.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Video from "vue-material-design-icons/Video.vue";
import { formatDateForEvent, formatDateTimeForEvent } from "@/utils/datetime";
import type { Locale } from "date-fns";
import LinkOrRouterLink from "../core/LinkOrRouterLink.vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

const props = withDefaults(
  defineProps<{
    event: IEvent;
    options?: IEventCardOptions;
    mode?: "row" | "column";
  }>(),
  { mode: "column" }
);
const defaultOptions: IEventCardOptions = {
  hideDate: false,
  loggedPerson: false,
  hideDetails: false,
  organizerActor: null,
  isRemoteEvent: false,
  isLoggedIn: true,
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

const formatBeginsOnDateWithCurrentLocale = computed(() => {
  if (!dateFnsLocale) return;
  return formatDateForEvent(new Date(props.event.beginsOn), dateFnsLocale);
});

const formatEndsOnDateWithCurrentLocale = computed(() => {
  if (!dateFnsLocale) return;
  return formatDateForEvent(new Date(props.event.endsOn), dateFnsLocale);
});

const formatDateTimeWithCurrentLocale = computed(() => {
  if (!dateFnsLocale) return;
  return formatDateTimeForEvent(new Date(props.event.beginsOn), dateFnsLocale);
});

const isInternal = computed(() => {
  return (
    mergedOptions.value.isRemoteEvent &&
    mergedOptions.value.isLoggedIn === false
  );
});

const to = computed(() => {
  if (mergedOptions.value.isRemoteEvent) {
    if (mergedOptions.value.isLoggedIn === false) {
      return props.event.url;
    }
    return {
      name: RouteName.INTERACT,
      query: { uri: encodeURI(props.event.url) },
    };
  }
  return { name: RouteName.EVENT, params: { uuid: props.event.uuid } };
});
</script>
