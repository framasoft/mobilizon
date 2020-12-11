<template>
  <div class="section container">
    <h1 class="title">
      {{ $t("My events") }}
    </h1>
    <p>
      {{
        $t(
          "You will find here all the events you have created or of which you are a participant."
        )
      }}
    </p>
    <div class="buttons">
      <router-link
        class="button is-primary"
        :to="{ name: RouteName.CREATE_EVENT }"
        >{{ $t("Create event") }}</router-link
      >
    </div>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <section v-if="futureParticipations.length > 0">
      <subtitle>
        {{ $t("Upcoming") }}
      </subtitle>
      <transition-group name="list" tag="p">
        <div v-for="month in monthlyFutureParticipations" :key="month[0]">
          <span class="upcoming-month">{{ month[0] }}</span>
          <EventListCard
            v-for="participation in month[1]"
            :key="participation.id"
            :participation="participation"
            :options="{ hideDate: false }"
            @event-deleted="eventDeleted"
            class="participation"
          />
        </div>
      </transition-group>
      <div class="columns is-centered">
        <b-button
          class="column is-narrow"
          v-if="
            hasMoreFutureParticipations && futureParticipations.length === limit
          "
          @click="loadMoreFutureParticipations"
          size="is-large"
          type="is-primary"
          >{{ $t("Load more") }}</b-button
        >
      </div>
    </section>
    <section v-if="drafts.length > 0">
      <subtitle>
        {{ $t("Drafts") }}
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
        {{ $t("Past events") }}
      </subtitle>
      <transition-group name="list" tag="p">
        <div v-for="month in monthlyPastParticipations" :key="month[0]">
          <span>{{ month[0] }}</span>
          <EventListCard
            v-for="participation in month[1]"
            :key="participation.id"
            :participation="participation"
            :options="{ hideDate: false }"
            @event-deleted="eventDeleted"
            class="participation"
          />
        </div>
      </transition-group>
      <div class="columns is-centered">
        <b-button
          class="column is-narrow"
          v-if="
            hasMorePastParticipations && pastParticipations.length === limit
          "
          @click="loadMorePastParticipations"
          size="is-large"
          type="is-primary"
          >{{ $t("Load more") }}</b-button
        >
      </div>
    </section>
    <section
      class="has-text-centered not-found"
      v-if="
        futureParticipations.length === 0 &&
        pastParticipations.length === 0 &&
        !$apollo.loading
      "
    >
      <div class="columns is-vertical is-centered">
        <div class="column is-three-quarters">
          <div class="img-container" :class="{ webp: supportsWebPFormat }" />
          <div class="content has-text-centered">
            <p>
              {{ $t("You didn't create or join any event yet.") }}
              <i18n path="Do you wish to {create_event} or {explore_events}?">
                <router-link
                  :to="{ name: RouteName.CREATE_EVENT }"
                  slot="create_event"
                  >{{ $t("create an event") }}</router-link
                >
                <router-link
                  :to="{ name: RouteName.SEARCH }"
                  slot="explore_events"
                  >{{ $t("explore the events") }}</router-link
                >
              </i18n>
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { ParticipantRole } from "@/types/enums";
import RouteName from "@/router/name";
import { supportsWebPFormat } from "@/utils/support";
import { IParticipant, Participant } from "../../types/participant.model";
import {
  LOGGED_USER_PARTICIPATIONS,
  LOGGED_USER_DRAFTS,
} from "../../graphql/actor";
import { EventModel, IEvent } from "../../types/event.model";
import EventListCard from "../../components/Event/EventListCard.vue";
import EventCard from "../../components/Event/EventCard.vue";
import Subtitle from "../../components/Utils/Subtitle.vue";

@Component({
  components: {
    Subtitle,
    EventCard,
    EventListCard,
  },
  apollo: {
    futureParticipations: {
      query: LOGGED_USER_PARTICIPATIONS,
      fetchPolicy: "cache-and-network",
      variables: {
        page: 1,
        limit: 10,
        afterDateTime: new Date().toISOString(),
      },
      update: (data) =>
        data.loggedUser.participations.elements.map(
          (participation: IParticipant) => new Participant(participation)
        ),
    },
    drafts: {
      query: LOGGED_USER_DRAFTS,
      fetchPolicy: "cache-and-network",
      variables: {
        page: 1,
        limit: 10,
      },
      update: (data) =>
        data.loggedUser.drafts.map((event: IEvent) => new EventModel(event)),
    },
    pastParticipations: {
      query: LOGGED_USER_PARTICIPATIONS,
      fetchPolicy: "cache-and-network",
      variables: {
        page: 1,
        limit: 10,
        beforeDateTime: new Date().toISOString(),
      },
      update: (data) =>
        data.loggedUser.participations.elements.map(
          (participation: IParticipant) => new Participant(participation)
        ),
    },
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t("My events") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class MyEvents extends Vue {
  futurePage = 1;

  pastPage = 1;

  limit = 10;

  futureParticipations: IParticipant[] = [];

  hasMoreFutureParticipations = true;

  pastParticipations: IParticipant[] = [];

  hasMorePastParticipations = true;

  drafts: IEvent[] = [];

  RouteName = RouteName;

  supportsWebPFormat = supportsWebPFormat;

  static monthlyParticipations(
    participations: IParticipant[],
    revertSort = false
  ): Map<string, Participant[]> {
    const res = participations.filter(
      ({ event, role }) =>
        event.beginsOn != null && role !== ParticipantRole.REJECTED
    );
    if (revertSort) {
      res.sort(
        (a: IParticipant, b: IParticipant) =>
          b.event.beginsOn.getTime() - a.event.beginsOn.getTime()
      );
    } else {
      res.sort(
        (a: IParticipant, b: IParticipant) =>
          a.event.beginsOn.getTime() - b.event.beginsOn.getTime()
      );
    }
    return res.reduce(
      (acc: Map<string, IParticipant[]>, participation: IParticipant) => {
        const month = new Date(participation.event.beginsOn).toLocaleDateString(
          undefined,
          {
            year: "numeric",
            month: "long",
          }
        );
        const filteredParticipations: IParticipant[] = acc.get(month) || [];
        filteredParticipations.push(participation);
        acc.set(month, filteredParticipations);
        return acc;
      },
      new Map()
    );
  }

  get monthlyFutureParticipations(): Map<string, Participant[]> {
    return MyEvents.monthlyParticipations(this.futureParticipations);
  }

  get monthlyPastParticipations(): Map<string, Participant[]> {
    return MyEvents.monthlyParticipations(this.pastParticipations, true);
  }

  loadMoreFutureParticipations(): void {
    this.futurePage += 1;
    this.$apollo.queries.futureParticipations.fetchMore({
      // New variables
      variables: {
        page: this.futurePage,
        limit: this.limit,
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const oldParticipations = previousResult.loggedUser.participations;
        const newParticipations = fetchMoreResult.loggedUser.participations;
        this.hasMoreFutureParticipations =
          newParticipations.total ===
          oldParticipations.length + newParticipations.length;

        return {
          loggedUser: {
            __typename: previousResult.loggedUser.__typename,
            participations: {
              __typename: newParticipations.__typename,
              total: newParticipations.total,
              elements: [
                ...oldParticipations.elements,
                ...newParticipations.elements,
              ],
            },
          },
        };
      },
    });
  }

  loadMorePastParticipations(): void {
    this.pastPage += 1;
    this.$apollo.queries.pastParticipations.fetchMore({
      // New variables
      variables: {
        page: this.pastPage,
        limit: this.limit,
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const oldParticipations = previousResult.loggedUser.participations;
        const newParticipations = fetchMoreResult.loggedUser.participations;
        this.hasMorePastParticipations =
          newParticipations.total ===
          oldParticipations.length + newParticipations.length;

        return {
          loggedUser: {
            __typename: previousResult.loggedUser.__typename,
            participations: {
              __typename: newParticipations.__typename,
              total: newParticipations.total,
              elements: [
                ...oldParticipations.elements,
                ...newParticipations.elements,
              ],
            },
          },
        };
      },
    });
  }

  eventDeleted(eventid: string): void {
    this.futureParticipations = this.futureParticipations.filter(
      (participation) => participation.event.id !== eventid
    );
    this.pastParticipations = this.pastParticipations.filter(
      (participation) => participation.event.id !== eventid
    );
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
main > .container {
  background: $white;

  & > h1 {
    margin: 10px auto 5px;
  }
}

.participation {
  margin: 1rem auto;
}

section {
  .upcoming-month {
    text-transform: capitalize;
  }
}

.not-found {
  .img-container {
    background-image: url("/img/pics/event_creation-480w.jpg");
    @media (min-resolution: 2dppx) {
      & {
        background-image: url("/img/pics/event_creation-1024w.jpg");
      }
    }

    &.webp {
      background-image: url("/img/pics/event_creation-480w.webp");
      @media (min-resolution: 2dppx) {
        & {
          background-image: url("/img/pics/event_creation-1024w.webp");
        }
      }
    }
    max-width: 450px;
    height: 300px;
    box-shadow: 0 0 8px 8px white inset;
    background-size: cover;
    border-radius: 10px;
    margin: auto auto 1rem;
  }
}
</style>
