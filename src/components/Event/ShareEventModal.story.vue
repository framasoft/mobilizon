<template>
  <Story>
    <Variant title="Public">
      <ShareEventModal :event="event" />
    </Variant>
    <Variant title="Private">
      <ShareEventModal
        :event="{ ...event, visibility: EventVisibility.PRIVATE }"
      />
    </Variant>
    <Variant title="Cancelled">
      <ShareEventModal :event="{ ...event, status: EventStatus.CANCELLED }" />
    </Variant>
    <Variant title="No seats left">
      <ShareEventModal :event="event" :event-capacity-o-k="false" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { EventVisibility, EventStatus } from "@/types/enums";
import ShareEventModal from "./ShareEventModal.vue";

const event = {
  title: "hello",
  url: "https://mobilizon.fr/events/an-uuid",
  visibility: EventVisibility.PUBLIC,
};
</script>
