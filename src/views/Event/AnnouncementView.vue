<template>
  <section class="container mx-auto" v-if="event">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MY_EVENTS, text: t('My events') },
        {
          name: RouteName.EVENT,
          params: { uuid: event.uuid },
          text: event.title,
        },
        {
          name: RouteName.ANNOUNCEMENTS,
          params: { uuid: event.uuid },
          text: t('Announcements'),
        },
      ]"
    />
    <EventConversations :event="event" class="my-6" />
    <NewPrivateMessage :event="event" />
  </section>
</template>

<script lang="ts" setup>
import RouteName from "@/router/name";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";
import EventConversations from "../../components/Conversations/EventConversations.vue";
import NewPrivateMessage from "../../components/Participation/NewPrivateMessage.vue";
import { useFetchEvent } from "@/composition/apollo/event";

const props = defineProps<{
  eventId: string;
}>();

const { t } = useI18n({ useScope: "global" });

const eventId = computed(() => props.eventId);

const { event } = useFetchEvent(eventId);

useHead({
  title: computed(() =>
    t("Announcements for {eventTitle}", { eventTitle: event.value?.title })
  ),
});
</script>
