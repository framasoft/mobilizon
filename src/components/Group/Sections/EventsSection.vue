<template>
  <group-section
    :title="longEvent ? t('Activities') : t('Events')"
    icon="calendar"
    :route="{
      name: RouteName.GROUP_EVENTS,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
  >
    <template #default>
      <div
        class="flex flex-wrap gap-2 p-2"
        v-if="group && group.organizedEvents.total > 0"
      >
        <event-minimalist-card
          v-for="event in group.organizedEvents.elements
            .filter((event) => (longEvent ? event.longEvent : !event.longEvent))
            .slice(0, 3)"
          :event="event"
          :key="event.uuid"
        />
      </div>
      <empty-content v-else-if="group" icon="calendar" :inline="true"
        >{{
          longEvent
            ? t("No public upcoming activities")
            : t("No public upcoming events")
        }}
      </empty-content>
      <!-- <o-skeleton animated v-else></o-skeleton> -->
    </template>
    <template #create>
      <o-button
        tag="router-link"
        class="button"
        variant="text"
        :to="{
          name: RouteName.GROUP_EVENTS,
          params: { preferredUsername: usernameWithDomain(group) },
          query: { showPassedEvents: true },
        }"
        >{{
          longEvent ? t("+ View past activities") : t("+ View past events")
        }}</o-button
      >
      <o-button
        tag="router-link"
        v-if="isModerator"
        :to="{
          name: RouteName.CREATE_EVENT,
          query: { actorId: group?.id },
        }"
        class="button is-primary"
        >{{
          longEvent ? t("+ Create an activity") : t("+ Create an event")
        }}</o-button
      >
    </template>
  </group-section>
</template>

<script lang="ts" setup>
import RouteName from "@/router/name";
import { IGroup } from "@/types/actor/group.model";
import { usernameWithDomain } from "@/types/actor";
import { useI18n } from "vue-i18n";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import EventMinimalistCard from "@/components/Event/EventMinimalistCard.vue";
import GroupSection from "@/components/Group/GroupSection.vue";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  group: IGroup;
  isModerator: boolean;
  longEvent: boolean;
}>();
</script>
