<template>
  <close-content
    class="container mx-auto px-2"
    :suggest-geoloc="false"
    v-show="loadingEvents || (events?.elements && events?.elements.length > 0)"
  >
    <template #title>
      {{ $t("Online upcoming events") }}
    </template>
    <template #content>
      <skeleton-event-result
        v-for="i in [...Array(6).keys()]"
        class="scroll-ml-6 snap-center shrink-0 w-[18rem] my-4"
        :key="i"
        v-show="loadingEvents"
      />
      <event-card
        class="scroll-ml-6 snap-center shrink-0 first:pl-8 last:pr-8 w-[18rem]"
        v-for="event in events?.elements"
        :key="event.id"
        :event="event"
        mode="column"
      />
      <more-content
        :to="{
          name: RouteName.SEARCH,
          query: {
            contentType: 'EVENTS',
            isOnline: 'true',
          },
        }"
        :picture="{
          url: '/img/online-event.webp',
          author: {
            name: 'Chris Montgomery',
            url: 'https://unsplash.com/@cwmonty',
          },
          source: {
            name: 'Unsplash',
            url: 'https://unsplash.com/?utm_source=Mobilizon&utm_medium=referral',
          },
        }"
      >
        {{ $t("View more online events") }}
      </more-content>
    </template>
  </close-content>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import SkeletonEventResult from "@/components/Event/SkeletonEventResult.vue";
import MoreContent from "./MoreContent.vue";
import CloseContent from "./CloseContent.vue";
import { SEARCH_EVENTS } from "@/graphql/search";
import EventCard from "@/components/Event/EventCard.vue";
import { useQuery } from "@vue/apollo-composable";
import RouteName from "@/router/name";
import { Paginate } from "@/types/paginate";
import { IEvent } from "@/types/event.model";

const EVENT_PAGE_LIMIT = 12;

const { result: searchEventResult, loading: loadingEvents } = useQuery<{
  searchEvents: Paginate<IEvent>;
}>(SEARCH_EVENTS, () => ({
  beginsOn: new Date(),
  endsOn: undefined,
  eventPage: 1,
  limit: EVENT_PAGE_LIMIT,
  type: "ONLINE",
}));

const events = computed(() => searchEventResult.value?.searchEvents);
</script>
