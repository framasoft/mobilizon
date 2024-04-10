<template>
  <FullCalendar
    ref="calendarRef"
    :options="calendarOptions"
    class="agenda-view"
  />

  <div v-if="listOfEventsByDate.date" class="my-4">
    <b v-text="formatDateString(listOfEventsByDate.date)" />

    <div v-if="listOfEventsByDate.events.length > 0">
      <div
        v-for="(event, index) in listOfEventsByDate.events"
        v-bind:key="index"
      >
        <div class="scroll-ml-6 snap-center shrink-0 my-4">
          <EventCard :event="event.event.extendedProps.event" />
        </div>
      </div>
    </div>

    <EmptyContent v-else icon="calendar" :inline="true">
      <span>
        {{ t("No events found") }}
      </span>
    </EmptyContent>
  </div>
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
import { EventSegment } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";
import {
  formatDateISOStringWithoutTime,
  formatDateString,
} from "@/filters/datetime";
import EventCard from "../Event/EventCard.vue";
import EmptyContent from "../Utils/EmptyContent.vue";

const { t } = useI18n({ useScope: "global" });

const calendarRef = ref();

const lastSelectedDate = ref<string | undefined>(new Date().toISOString());

const listOfEventsByDate = ref<{ events: EventSegment[]; date?: string }>({
  events: [],
  date: undefined,
});

const showEventsByDate = (dateStr: string) => {
  dateStr = formatDateISOStringWithoutTime(dateStr);
  const moreLinkElement = document.querySelectorAll(
    `td[data-date='${dateStr}'] a.fc-more-link`
  )[0] as undefined | HTMLElement;

  if (moreLinkElement) {
    moreLinkElement.click();
  } else {
    listOfEventsByDate.value = {
      events: [],
      date: dateStr,
    };
  }

  calendarRef.value.getApi().select(dateStr);
};

if (window.location.hash.length) {
  lastSelectedDate.value = formatDateISOStringWithoutTime(
    window.location.hash.replace("#_", "")
  );
} else {
  lastSelectedDate.value = formatDateISOStringWithoutTime(
    new Date().toISOString()
  );
}

const { load: searchEventsLoad, refetch: searchEventsRefetch } = useLazyQuery<{
  searchEvents: Paginate<IEvent>;
}>(SEARCH_CALENDAR_EVENTS);

const calendarOptions = computed((): object => {
  return {
    plugins: [dayGridPlugin, interactionPlugin],
    initialView: "dayGridMonth",
    initialDate: lastSelectedDate.value,
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
            url: event.url,
            extendedProps: {
              event: event,
            },
          };
        })
      );
    },
    nextDayThreshold: "09:00:00",
    dayMaxEventRows: 0,
    moreLinkClassNames: "bg-mbz-yellow dark:bg-mbz-purple dark:text-white",
    moreLinkContent: (arg: { num: number; text: string }) => {
      return "+" + arg.num.toString();
    },
    contentHeight: "auto",
    eventClassNames: "line-clamp-3 bg-mbz-yellow dark:bg-mbz-purple",
    headerToolbar: {
      left: "prev,next,customTodayButton",
      center: "",
      right: "title",
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
    customButtons: {
      customTodayButton: {
        text: t("Today"),
        click: () => {
          calendarRef.value.getApi().today();
          lastSelectedDate.value = formatDateISOStringWithoutTime(
            new Date().toISOString()
          );
        },
      },
    },
    dateClick: (info: { dateStr: string }) => {
      showEventsByDate(info.dateStr);
    },
    moreLinkClick: (info: {
      date: Date;
      allSegs: EventSegment[];
      hiddenSegs: EventSegment[];
      jsEvent: object;
    }) => {
      listOfEventsByDate.value = {
        events: info.allSegs,
        date: info.date.toISOString(),
      };

      if (info.allSegs.length) {
        window.location.hash =
          "_" + formatDateISOStringWithoutTime(info.date.toISOString());
      }

      return "none";
    },
    moreLinkDidMount: (arg: { el: Element }) => {
      if (
        lastSelectedDate.value &&
        arg.el.closest(`td[data-date='${lastSelectedDate.value}']`)
      ) {
        showEventsByDate(lastSelectedDate.value);
        lastSelectedDate.value = undefined;
      }
    },
  };
});
</script>

<style>
.agenda-view .fc-button {
  font-size: 0.8rem !important;
}

.agenda-view .fc-toolbar-title {
  font-size: 1rem !important;
}

.agenda-view .fc-daygrid-day-events {
  min-height: 1.1rem !important;
  margin-bottom: 0.2rem !important;
  margin-left: 0.1rem !important;
}

.agenda-view .fc-more-link {
  pointer-events: none !important;
}

.clock-icon {
  display: inline-block;
  vertical-align: middle;
}

.time {
  font-size: 0.95rem !important;
}
</style>
