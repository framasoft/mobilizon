<template>
  <div>
    <p class="time">
      {{
        formatDistanceToNow(new Date(event.publishAt || event.insertedAt), {
          locale: $dateFnsLocale,
          addSuffix: true,
        }) || $t("Right now")
      }}
    </p>
    <EventCard :event="event" />
  </div>
</template>
<script lang="ts">
import { IEvent } from "@/types/event.model";
import { formatDistanceToNow } from "date-fns";
import { Component, Prop, Vue } from "vue-property-decorator";
import EventCard from "./EventCard.vue";

@Component({
  components: {
    EventCard,
  },
})
export default class RecentEventCardWrapper extends Vue {
  @Prop({ required: true, type: Object }) event!: IEvent;

  formatDistanceToNow = formatDistanceToNow;
}
</script>
<style lang="scss" scoped>
p.time {
  color: $orange-2;
}
</style>
