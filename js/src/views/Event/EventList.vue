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
    <b-message v-if-else="events.length === 0 && $apollo.loading === false" type="is-danger">{{
      $t("No events found")
    }}</b-message>
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

  // created() {
  //   this.fetchData(this.$router.currentRoute.params.location);
  // }

  // beforeRouteUpdate(to, from, next) {
  //   this.fetchData(to.params.location);
  //   next();
  // }

  // @Watch('locationChip')
  // onLocationChipChange(val) {
  //   if (val === false) {
  //     this.$router.push({ name: RouteName.EVENT_LIST });
  //   }
  // }

  // geocode(lat, lon) {
  //   console.log({ lat, lon });
  //   console.log(ngeohash.encode(lat, lon, 10));
  //   return ngeohash.encode(lat, lon, 10);
  // }

  // fetchData(location: string) {
  //   let queryString = '/events';
  //   if (location) {
  //     queryString += `?geohash=${location}`;
  //     const { latitude, longitude } = ngeohash.decode(location);
  //     this.locationText = `${latitude.toString()} : ${longitude.toString()}`;
  //   }
  //   this.locationChip = true;
  //   // FIXME: remove eventFetch
  //   // eventFetch(queryString, this.$store)
  //   //   .then(response => response.json())
  //   //   .then((response) => {
  //   //     this.loading = false;
  //   //     this.events = response.data;
  //   //     console.log(this.events);
  //   //   });
  // }

  // deleteEvent(event: IEvent) {
  //   const router = this.$router;
  //   // FIXME: remove eventFetch
  //   // eventFetch(`/events/${event.uuid}`, this.$store, { method: 'DELETE' })
  //   //   .then(() => router.push('/events'));
  // }

  viewEvent(event: IEvent) {
    this.$router.push({ name: RouteName.EVENT, params: { uuid: event.uuid } });
  }

  // downloadIcsEvent(event: IEvent) {
  //   // FIXME: remove eventFetch
  //   // eventFetch(`/events/${event.uuid}/ics`, this.$store, { responseType: 'arraybuffer' })
  //   //   .then(response => response.text())
  //   //   .then((response) => {
  //   //     const blob = new Blob([ response ], { type: 'text/calendar' });
  //   //     const link = document.createElement('a');
  //   //     link.href = window.URL.createObjectURL(blob);
  //   //     link.download = `${event.title}.ics`;
  //   //     document.body.appendChild(link);
  //   //     link.click();
  //   //     document.body.removeChild(link);
  //   //   });
  // }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped></style>
