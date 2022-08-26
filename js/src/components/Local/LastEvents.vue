<template>
  <close-content
    class="container mx-auto px-2"
    v-show="loadingEvents || (events && events.total > 0)"
    :suggestGeoloc="false"
    v-on="attrs"
  >
    <template #title>
      {{ t("Last published events") }}
    </template>
    <template #subtitle>
      <i18n-t
        class="text-slate-700 dark:text-slate-300"
        tag="p"
        keypath="On {instance} and other federated instances"
      >
        <template #instance>
          <b>{{ instanceName }}</b>
        </template>
      </i18n-t>
    </template>
    <template #content>
      <skeleton-event-result
        v-for="i in 6"
        class="scroll-ml-6 snap-center shrink-0 w-[18rem] my-4"
        :key="i"
        v-show="loadingEvents"
      />
      <event-card
        v-for="event in events.elements"
        :event="event"
        :key="event.uuid"
      />
      <more-content
        :to="{
          name: RouteName.SEARCH,
          query: {
            contentType: 'EVENTS',
          },
        }"
      >
        {{ t("View more events") }}
      </more-content>
    </template>
  </close-content>
</template>

<script lang="ts" setup>
import MoreContent from "./MoreContent.vue";
import CloseContent from "./CloseContent.vue";
import { computed, useAttrs } from "vue";
import { IEvent } from "@/types/event.model";
import { useQuery } from "@vue/apollo-composable";
import EventCard from "../Event/EventCard.vue";
import { Paginate } from "@/types/paginate";
import SkeletonEventResult from "../Event/SkeletonEventResult.vue";
import { EventSortField, SortDirection } from "@/types/enums";
import { FETCH_EVENTS } from "@/graphql/event";
import { useI18n } from "vue-i18n";
import RouteName from "@/router/name";

defineProps<{
  instanceName: string;
}>();

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

const { result: resultEvents, loading: loadingEvents } = useQuery<{
  events: Paginate<IEvent>;
}>(FETCH_EVENTS, {
  orderBy: EventSortField.INSERTED_AT,
  direction: SortDirection.DESC,
});
const events = computed(
  () => resultEvents.value?.events ?? { total: 0, elements: [] }
);
</script>
