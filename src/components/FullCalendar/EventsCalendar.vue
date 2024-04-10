<template>
  <FullCalendar ref="calendarRef" :options="calendarOptions">
    <template v-slot:eventContent="arg">
      <span
        class="text-violet-3 dark:text-white font-bold m-2"
        :title="arg.event.title"
      >
        {{ arg.event.title }}
      </span>
    </template>
  </FullCalendar>
</template>

<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { locale } from "@/utils/i18n";
import { computed, ref } from "vue";
import { useLazyQuery } from "@vue/apollo-composable";
import { IEvent } from "@/types/event.model";
import { Paginate } from "@/types/paginate";
import { SEARCH_CALENDAR_EVENTS } from "@/graphql/search";
import FullCalendar from "@fullcalendar/vue3";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";

const calendarRef = ref();

const { t } = useI18n({ useScope: "global" });

const { load: searchEventsLoad, refetch: searchEventsRefetch } = useLazyQuery<{
  searchEvents: Paginate<IEvent>;
}>(SEARCH_CALENDAR_EVENTS);

const calendarOptions = computed((): object => {
  return {
    plugins: [dayGridPlugin, interactionPlugin],
    initialView: "dayGridMonth",
    events: async (
      info: { start: Date; end: Date; startStr: string; endStr: string },
      successCallback: (arg: object[]) => unknown,
      failureCallback: (err: string) => unknown
    ) => {
      const queryVars = {
        limit: 999,
        beginsOn: info.start,
        endsOn: info.end,
      };

      const result =
        (await searchEventsLoad(undefined, queryVars)) ||
        (await searchEventsRefetch(queryVars))?.data;

      if (!result) {
        failureCallback("failed to fetch calendar events");
        return;
      }

      successCallback(
        (result.searchEvents.elements ?? []).map((event: IEvent) => {
          return {
            id: event.id,
            title: event.title,
            start: event.beginsOn,
            end: event.endsOn,
            startStr: event.beginsOn,
            endStr: event.endsOn,
            url: `/events/${event.uuid}`,
            extendedProps: {
              event: event,
            },
          };
        })
      );
    },
    nextDayThreshold: "09:00:00",
    dayMaxEventRows: 5,
    moreLinkClassNames: "bg-mbz-yellow dark:bg-mbz-purple dark:text-white p-2",
    moreLinkContent: (arg: { num: number; text: string }) => {
      return "+" + arg.num.toString();
    },
    eventClassNames: "line-clamp-3 bg-mbz-yellow dark:bg-mbz-purple",
    headerToolbar: {
      left: "prev,next,today",
      center: "title",
      right: "dayGridWeek,dayGridMonth", // user can switch between the two
    },
    locale: locale,
    firstDay: 1,
    buttonText: {
      today: t("Today"),
      month: t("Month"),
      week: t("Week"),
      day: t("Day"),
      list: t("List"),
    },
  };
});
</script>

<style>
.fc-popover-header {
  color: black !important;
}
</style>
