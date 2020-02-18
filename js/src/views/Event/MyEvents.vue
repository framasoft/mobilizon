<template>
    <section class="section container">
        <h1 class="title">
            {{ $t('My events') }}
        </h1>
        <b-loading :active.sync="$apollo.loading"></b-loading>
        <section v-if="futureParticipations.length > 0">
            <subtitle>
                {{ $t('Upcoming') }}
            </subtitle>
            <transition-group name="list" tag="p">
                <div v-for="month in monthlyFutureParticipations" :key="month[0]">
                    <h3 class="upcoming-month">{{ month[0] }}</h3>
                    <EventListCard
                            v-for="participation in month[1]"
                            :key="participation.id"
                            :participation="participation"
                            :options="{ hideDate: false }"
                            @eventDeleted="eventDeleted"
                            class="participation"
                    />
                </div>
            </transition-group>
            <div class="columns is-centered">
                <b-button class="column is-narrow"
                          v-if="hasMoreFutureParticipations && (futureParticipations.length === limit)" @click="loadMoreFutureParticipations" size="is-large" type="is-primary">{{ $t('Load more') }}</b-button>
            </div>
        </section>
        <section v-if="drafts.length > 0">
            <subtitle>
                {{ $t('Drafts') }}
            </subtitle>
            <div class="columns is-multiline">
                <EventCard
                        v-for="draft in drafts"
                        :key="draft.uuid"
                        :event="draft"
                        class="is-one-quarter-desktop column"
                />
            </div>
        </section>
        <section v-if="pastParticipations.length > 0">
            <subtitle>
                {{ $t('Past events') }}
            </subtitle>
            <transition-group name="list" tag="p">
                <div v-for="month in monthlyPastParticipations" :key="month[0]">
                    <h3>{{ month[0] }}</h3>
                    <EventListCard
                            v-for="participation in month[1]"
                            :key="participation.id"
                            :participation="participation"
                            :options="{ hideDate: false }"
                            @eventDeleted="eventDeleted"
                            class="participation"
                    />
                </div>
            </transition-group>
            <div class="columns is-centered">
                <b-button class="column is-narrow"
                          v-if="hasMorePastParticipations && (pastParticipations.length === limit)" @click="loadMorePastParticipations" size="is-large" type="is-primary">{{ $t('Load more') }}</b-button>
            </div>
        </section>
        <b-message v-if="futureParticipations.length === 0 && pastParticipations.length === 0 && $apollo.loading === false" type="is-danger">
            {{ $t('No events found') }}
        </b-message>
    </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { LOGGED_USER_PARTICIPATIONS, LOGGED_USER_DRAFTS } from '@/graphql/actor';
import { EventModel, IEvent, IParticipant, Participant, ParticipantRole } from '@/types/event.model';
import EventListCard from '@/components/Event/EventListCard.vue';
import EventCard from '@/components/Event/EventCard.vue';
import Subtitle from '@/components/Utils/Subtitle.vue';


@Component({
  components: {
    Subtitle,
    EventCard,
    EventListCard,
  },
  apollo: {
    futureParticipations: {
      query: LOGGED_USER_PARTICIPATIONS,
      fetchPolicy: 'network-only',
      variables: {
        page: 1,
        limit: 10,
        afterDateTime: (new Date()).toISOString(),
      },
      update: data => data.loggedUser.participations.map(participation => new Participant(participation)),
    },
    drafts: {
      query: LOGGED_USER_DRAFTS,
      fetchPolicy: 'network-only',
      variables: {
        page: 1,
        limit: 10,
      },
      update: data => data.loggedUser.drafts.map(event => new EventModel(event)),
    },
    pastParticipations: {
      query: LOGGED_USER_PARTICIPATIONS,
      fetchPolicy: 'network-only',
      variables: {
        page: 1,
        limit: 10,
        beforeDateTime: (new Date()).toISOString(),
      },
      update: data => data.loggedUser.participations.map(participation => new Participant(participation)),
    },
  },
  metaInfo() {
    return {
            // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t('My events') as string,
            // all titles will be injected into this template
      titleTemplate: '%s | Mobilizon',
    };
  },
})
export default class MyEvents extends Vue {
  futurePage: number = 1;
  pastPage: number = 1;
  limit: number = 10;

  futureParticipations: IParticipant[] = [];
  hasMoreFutureParticipations: boolean = true;

  pastParticipations: IParticipant[] = [];
  hasMorePastParticipations: boolean = true;

  drafts: IEvent[] = [];

  private monthlyParticipations(participations: IParticipant[]): Map<string, Participant[]> {
    const res = participations.filter(({ event, role }) => event.beginsOn != null && role !== ParticipantRole.REJECTED);
    res.sort(
          (a: IParticipant, b: IParticipant) => a.event.beginsOn.getTime() - b.event.beginsOn.getTime(),
      );
    return res.reduce((acc: Map<string, IParticipant[]>, participation: IParticipant) => {
      const month = (new Date(participation.event.beginsOn)).toLocaleDateString(undefined, { year: 'numeric', month: 'long' });
      const participations: IParticipant[] = acc.get(month) || [];
      participations.push(participation);
      acc.set(month, participations);
      return acc;
    },                new Map());
  }

  get monthlyFutureParticipations(): Map<string, Participant[]> {
    return this.monthlyParticipations(this.futureParticipations);
  }

  get monthlyPastParticipations(): Map<string, Participant[]> {
    return this.monthlyParticipations(this.pastParticipations);
  }

  loadMoreFutureParticipations() {
    this.futurePage += 1;
    this.$apollo.queries.futureParticipations.fetchMore({
      // New variables
      variables: {
        page: this.futurePage,
        limit: this.limit,
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const newParticipations = fetchMoreResult.loggedUser.participations;
        this.hasMoreFutureParticipations = newParticipations.length === this.limit;

        return {
          loggedUser: {
            __typename: previousResult.loggedUser.__typename,
            participations: [...previousResult.loggedUser.participations, ...newParticipations],
          },
        };
      },
    });
  }

  loadMorePastParticipations() {
    this.pastPage += 1;
    this.$apollo.queries.pastParticipations.fetchMore({
            // New variables
      variables: {
        page: this.pastPage,
        limit: this.limit,
      },
            // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const newParticipations = fetchMoreResult.loggedUser.participations;
        this.hasMorePastParticipations = newParticipations.length === this.limit;

        return {
          loggedUser: {
            __typename: previousResult.loggedUser.__typename,
            participations: [...previousResult.loggedUser.participations, ...newParticipations],
          },
        };
      },
    });
  }

  eventDeleted(eventid) {
    this.futureParticipations = this.futureParticipations.filter(participation => participation.event.id !== eventid);
    this.pastParticipations = this.pastParticipations.filter(participation => participation.event.id !== eventid);
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
    @import "../../variables";

    main > .container {
        background: $white;
    }

    .participation {
        margin: 1rem auto;
    }

    section {
        .upcoming-month {
            text-transform: capitalize;
        }
    }
</style>
