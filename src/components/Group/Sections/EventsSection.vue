<template>
  <group-section
    :title="t('Events')"
    icon="calendar"
    :privateSection="false"
    :route="{
      name: RouteName.GROUP_EVENTS,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
  >
    <template #default>
      <div
        class="flex flex-wrap gap-2 py-1"
        v-if="group && group.organizedEvents.total > 0"
      >
        <event-minimalist-card
          v-for="event in group.organizedEvents.elements.slice(0, 3)"
          :event="event"
          :key="event.uuid"
        />
      </div>
      <empty-content v-else-if="group" icon="calendar" :inline="true">
        {{ t("No public upcoming events") }}
      </empty-content>
      <!-- <o-skeleton animated v-else></o-skeleton> -->
    </template>
    <template #create>
      <o-button
        tag="router-link"
        v-if="isModerator"
        :to="{
          name: RouteName.CREATE_EVENT,
          query: { actorId: group?.id },
        }"
        class="button is-primary"
        >{{ t("+ Create an event") }}</o-button
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

defineProps<{ group: IGroup; isModerator: boolean }>();
</script>
