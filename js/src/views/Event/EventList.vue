<template>
  <section class="container">
    <h1>{{ $t("Event list") }}</h1>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div v-if="events.length > 0" class="columns is-multiline">
      <EventCard
        v-for="event in events"
        :key="event.uuid"
        :event="event"
        class="column is-one-quarter-desktop is-half-mobile"
      />
    </div>
    <b-message
      v-if-else="events.length === 0 && $apollo.loading === false"
      type="is-danger"
      >{{ $t("No events found") }}</b-message
    >
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import EventCard from "../../components/Event/EventCard.vue";
import RouteName from "../../router/name";
import { IEvent } from "../../types/event.model";

@Component({
  components: {
    EventCard,
  },
})
export default class EventList extends Vue {
  @Prop(String) location!: string;

  events = [];

  loading = true;

  locationChip = false;

  locationText = "";

  viewEvent(event: IEvent): void {
    this.$router.push({ name: RouteName.EVENT, params: { uuid: event.uuid } });
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped></style>
