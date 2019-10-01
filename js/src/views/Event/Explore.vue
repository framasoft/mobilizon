<template>
  <section class="container">
    <h1 class="title">{{ $t('Explore') }}</h1>
<!--    <pre>{{ events }}</pre>-->
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div v-if="events.length > 0" class="columns is-multiline">
      <EventCard
        v-for="event in events"
        :key="event.uuid"
        :event="event"
        class="column is-one-quarter-desktop"
      />
    </div>
    <b-message v-else-if="events.length === 0 && $apollo.loading === false" type="is-danger">
      {{ $t('No events found') }}
    </b-message>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { FETCH_EVENTS } from '@/graphql/event';
import { IEvent } from '@/types/event.model';

@Component({
  components: {
    EventCard,
  },
  apollo: {
    events: {
      query: FETCH_EVENTS,
    },
  },
})
export default class Explore extends Vue {
  events: IEvent[] = [];
}
</script>

<style scoped>
</style>
