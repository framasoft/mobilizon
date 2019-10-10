<template>
  <div class="container">
    <h1 class="title">{{ $t('Explore') }}</h1>
    <section class="hero">
      <div class="hero-body">
        <form @submit="submit()">
          <b-field :label="$t('Event')" grouped label-position="on-border">
            <b-input icon="magnify" type="search" size="is-large" expanded v-model="searchTerm" :placeholder="$t('For instance: London, Taekwondo, Architecture…')" />
            <p class="control">
              <b-button @click="submit" type="is-info" size="is-large">{{ $t('Search') }}</b-button>
            </p>
          </b-field>
        </form>
      </div>
    </section>
    <section class="events-featured">
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <h3 class="title">{{ $t('Featured events') }}</h3>
      <div v-if="events.length > 0" class="columns is-multiline">
        <div class="column is-one-quarter-desktop" v-for="event in events" :key="event.uuid">
          <EventCard
            :event="event"
          />
        </div>
      </div>
      <b-message v-else-if="events.length === 0 && $apollo.loading === false" type="is-danger">
        {{ $t('No events found') }}
      </b-message>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { FETCH_EVENTS } from '@/graphql/event';
import { IEvent } from '@/types/event.model';
import { RouteName } from '@/router';

@Component({
  components: {
    EventCard,
  },
  apollo: {
    events: {
      query: FETCH_EVENTS,
    },
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t('Explore') as string,
      // all titles will be injected into this template
      titleTemplate: '%s | Mobilizon',
    };
  },
})
export default class Explore extends Vue {
  events: IEvent[] = [];
  searchTerm: string = '';

  submit() {
    this.$router.push({ name: RouteName.SEARCH, params: { searchTerm: this.searchTerm } });
  }
}
</script>

<style scoped lang="scss">
  h1.title {
    margin-top: 1.5rem;
  }

  h3.title {
    margin-bottom: 1.5rem;
  }

  .events-featured {
    margin: 25px auto;

    .columns {
      margin: 1rem auto 3rem;
    }
}
</style>
