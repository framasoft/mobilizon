<template>
  <div class="container mx-auto px-1 mb-6">
    <h1 v-if="!isMobile">
      {{ t("Calendar") }}
    </h1>

    <div class="p-2">
      <EventsCalendar v-if="!isMobile" />
      <EventsAgenda v-else />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import EventsAgenda from "@/components/FullCalendar/EventsAgenda.vue";
import EventsCalendar from "@/components/FullCalendar/EventsCalendar.vue";

const { t } = useI18n({ useScope: "global" });

const isMobile = window.innerWidth < 760;
</script>
