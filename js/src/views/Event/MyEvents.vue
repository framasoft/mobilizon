<template>
  <div class="section container">
    <h1 class="title">
      {{ $t("My events") }}
    </h1>
    <p>
      {{
        $t(
          "You will find here all the events you have created or of which you are a participant, as well as events organized by groups you follow or are a member of."
        )
      }}
    </p>
    <div class="buttons" v-if="!hideCreateEventButton">
      <router-link
        class="button is-primary"
        :to="{ name: RouteName.CREATE_EVENT }"
        >{{ $t("Create event") }}</router-link
      >
    </div>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div class="wrapper">
      <div class="event-filter">
        <b-field grouped group-multiline>
          <b-field>
            <b-switch v-model="showUpcoming">{{
              showUpcoming ? $t("Upcoming events") : $t("Past events")
            }}</b-switch>
          </b-field>
          <b-field v-if="showUpcoming">
            <b-checkbox v-model="showDrafts">{{ $t("Drafts") }}</b-checkbox>
          </b-field>
          <b-field v-if="showUpcoming">
            <b-checkbox v-model="showAttending">{{
              $t("Attending")
            }}</b-checkbox>
          </b-field>
          <b-field v-if="showUpcoming">
            <b-checkbox v-model="showMyGroups">{{
              $t("From my groups")
            }}</b-checkbox>
          </b-field>
          <p v-if="!showUpcoming">
            {{
              $tc(
                "You have attended {count} events in the past.",
                pastParticipations.total,
                {
                  count: pastParticipations.total,
                }
              )
            }}
          </p>
          <b-field
            class="date-filter"
            expanded
            :label="
              showUpcoming
                ? $t('Showing events starting on')
                : $t('Showing events before')
            "
          >
            <b-datepicker v-model="dateFilter" />
            <b-button
              @click="dateFilter = new Date()"
              class="reset-area"
              icon-left="close"
              :title="$t('Clear date filter field')"
            />
          </b-field>
        </b-field>
      </div>
      <div class="my-events">
        <section
          class="py-4"
          v-if="showUpcoming && showDrafts && drafts.length > 0"
        >
          <multi-event-minimalist-card :events="drafts" :showOrganizer="true" />
        </section>
        <section
          class="py-4"
          v-if="
            showUpcoming && monthlyFutureEvents && monthlyFutureEvents.size > 0
          "
        >
          <transition-group name="list" tag="p">
            <div
              class="mb-5"
              v-for="month in monthlyFutureEvents"
              :key="month[0]"
            >
              <span class="upcoming-month">{{ month[0] }}</span>
              <div v-for="element in month[1]" :key="element.id">
                <event-participation-card
                  v-if="'role' in element"
                  :participation="element"
                  :options="{ hideDate: false }"
                  @event-deleted="eventDeleted"
                  class="participation"
                />
                <event-minimalist-card
                  v-else-if="
                    !monthParticipationsIds(month[1]).includes(element.id)
                  "
                  :event="element"
                  class="participation"
                />
              </div>
            </div>
          </transition-group>
          <div class="columns is-centered">
            <b-button
              class="column is-narrow"
              v-if="
                hasMoreFutureParticipations &&
                futureParticipations &&
                futureParticipations.length === limit
              "
              @click="loadMoreFutureParticipations"
              size="is-large"
              type="is-primary"
              >{{ $t("Load more") }}</b-button
            >
          </div>
        </section>
        <section
          class="has-text-centered not-found"
          v-if="
            showUpcoming &&
            monthlyFutureEvents &&
            monthlyFutureEvents.size === 0 &&
            !$apollo.loading
          "
        >
          <div class="img-container" :class="{ webp: supportsWebPFormat }" />
          <div class="content has-text-centered">
            <p>
              {{
                $t(
                  "You don't have any upcoming events. Maybe try another filter?"
                )
              }}
            </p>
            <i18n
              path="Do you wish to {create_event} or {explore_events}?"
              tag="p"
            >
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
          </div>
        </section>
        <section v-if="!showUpcoming && pastParticipations.elements.length > 0">
          <transition-group name="list" tag="p">
            <div v-for="month in monthlyPastParticipations" :key="month[0]">
              <span class="past-month">{{ month[0] }}</span>
              <event-participation-card
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
                hasMorePastParticipations &&
                pastParticipations.elements.length === limit
              "
              @click="loadMorePastParticipations"
              size="is-large"
              type="is-primary"
              >{{ $t("Load more") }}</b-button
            >
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import { Component, Vue } from "vue-property-decorator";
import { ParticipantRole } from "@/types/enums";
import RouteName from "@/router/name";
import { supportsWebPFormat } from "@/utils/support";
import { IParticipant, Participant } from "../../types/participant.model";
import { LOGGED_USER_DRAFTS } from "../../graphql/actor";
import { EventModel, IEvent } from "../../types/event.model";
import EventParticipationCard from "../../components/Event/EventParticipationCard.vue";
import MultiEventMinimalistCard from "../../components/Event/MultiEventMinimalistCard.vue";
import EventMinimalistCard from "../../components/Event/EventMinimalistCard.vue";
import Subtitle from "../../components/Utils/Subtitle.vue";
import {
  LOGGED_USER_PARTICIPATIONS,
  LOGGED_USER_UPCOMING_EVENTS,
} from "@/graphql/participant";
import { Paginate } from "@/types/paginate";

type Eventable = IParticipant | IEvent;

@Component({
  components: {
    Subtitle,
    MultiEventMinimalistCard,
    EventParticipationCard,
    EventMinimalistCard,
  },
  apollo: {
    config: CONFIG,
    userUpcomingEvents: {
      query: LOGGED_USER_UPCOMING_EVENTS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          page: 1,
          limit: 10,
          afterDateTime: this.dateFilter,
        };
      },
      update(data) {
        this.futureParticipations = data.loggedUser.participations.elements.map(
          (participation: IParticipant) => new Participant(participation)
        );
        this.groupEvents = data.loggedUser.followedGroupEvents.elements.map(
          ({ event }: { event: IEvent }) => event
        );
      },
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
      variables() {
        return {
          page: 1,
          limit: 10,
          beforeDateTime: this.dateFilter,
        };
      },
      update: (data) => data.loggedUser.participations,
    },
  },
  metaInfo() {
    return {
      title: this.$t("My events") as string,
    };
  },
})
export default class MyEvents extends Vue {
  futurePage = 1;

  pastPage = 1;

  limit = 10;

  get showUpcoming(): boolean {
    return ((this.$route.query.showUpcoming as string) || "true") === "true";
  }

  set showUpcoming(showUpcoming: boolean) {
    this.$router.push({
      name: RouteName.MY_EVENTS,
      query: { ...this.$route.query, showUpcoming: showUpcoming.toString() },
    });
  }

  get showDrafts(): boolean {
    return ((this.$route.query.showDrafts as string) || "true") === "true";
  }

  set showDrafts(showDrafts: boolean) {
    this.$router.push({
      name: RouteName.MY_EVENTS,
      query: { ...this.$route.query, showDrafts: showDrafts.toString() },
    });
  }

  get showAttending(): boolean {
    return ((this.$route.query.showAttending as string) || "true") === "true";
  }

  set showAttending(showAttending: boolean) {
    this.$router.push({
      name: RouteName.MY_EVENTS,
      query: { ...this.$route.query, showAttending: showAttending.toString() },
    });
  }

  get showMyGroups(): boolean {
    return ((this.$route.query.showMyGroups as string) || "false") === "true";
  }

  set showMyGroups(showMyGroups: boolean) {
    this.$router.push({
      name: RouteName.MY_EVENTS,
      query: { ...this.$route.query, showMyGroups: showMyGroups.toString() },
    });
  }

  get dateFilter(): Date {
    const query = this.$route.query.dateFilter as string;
    if (query && /(\d{4}-\d{2}-\d{2})/.test(query)) {
      return new Date(`${query}T00:00:00Z`);
    }
    return new Date();
  }

  set dateFilter(date: Date) {
    const pad = (number: number) => {
      if (number < 10) {
        return "0" + number;
      }
      return number;
    };
    const stringifiedDate = `${date.getFullYear()}-${pad(
      date.getMonth() + 1
    )}-${pad(date.getDate())}`;

    if (this.$route.query.dateFilter !== stringifiedDate) {
      this.$router.push({
        name: RouteName.MY_EVENTS,
        query: {
          ...this.$route.query,
          dateFilter: stringifiedDate,
        },
      });
    }
  }

  config!: IConfig;

  futureParticipations: IParticipant[] = [];

  groupEvents: IEvent[] = [];

  hasMoreFutureParticipations = true;

  pastParticipations: Paginate<IParticipant> = { elements: [], total: 0 };

  hasMorePastParticipations = true;

  drafts: IEvent[] = [];

  RouteName = RouteName;

  supportsWebPFormat = supportsWebPFormat;

  static monthlyEvents(
    elements: Eventable[],
    revertSort = false
  ): Map<string, Eventable[]> {
    const res = elements.filter((element: Eventable) => {
      if ("role" in element) {
        return (
          element.event.beginsOn != null &&
          element.role !== ParticipantRole.REJECTED
        );
      }
      return element.beginsOn != null;
    });
    if (revertSort) {
      res.sort((a: Eventable, b: Eventable) => {
        const aTime = "role" in a ? a.event.beginsOn : a.beginsOn;
        const bTime = "role" in b ? b.event.beginsOn : b.beginsOn;
        return new Date(bTime).getTime() - new Date(aTime).getTime();
      });
    } else {
      res.sort((a: Eventable, b: Eventable) => {
        const aTime = "role" in a ? a.event.beginsOn : a.beginsOn;
        const bTime = "role" in b ? b.event.beginsOn : b.beginsOn;
        return new Date(aTime).getTime() - new Date(bTime).getTime();
      });
    }
    return res.reduce((acc: Map<string, Eventable[]>, element: Eventable) => {
      const month = new Date(
        "role" in element ? element.event.beginsOn : element.beginsOn
      ).toLocaleDateString(undefined, {
        year: "numeric",
        month: "long",
      });
      const filteredElements: Eventable[] = acc.get(month) || [];
      filteredElements.push(element);
      acc.set(month, filteredElements);
      return acc;
    }, new Map());
  }

  get monthlyFutureEvents(): Map<string, Eventable[]> {
    let eventable = [] as Eventable[];
    if (this.showAttending) {
      eventable = [...eventable, ...this.futureParticipations];
    }
    if (this.showMyGroups) {
      eventable = [...eventable, ...this.groupEvents];
    }
    return MyEvents.monthlyEvents(eventable);
  }

  get monthlyPastParticipations(): Map<string, Eventable[]> {
    return MyEvents.monthlyEvents(this.pastParticipations.elements, true);
  }

  monthParticipationsIds(elements: Eventable[]): string[] {
    let res = elements.filter((element: Eventable) => {
      return "role" in element;
    }) as IParticipant[];
    return res.map(({ event }: { event: IEvent }) => {
      return event.id as string;
    });
  }

  loadMoreFutureParticipations(): void {
    this.futurePage += 1;
    this.$apollo.queries.futureParticipations.fetchMore({
      // New variables
      variables: {
        page: this.futurePage,
        limit: this.limit,
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
    });
  }

  eventDeleted(eventid: string): void {
    this.futureParticipations = this.futureParticipations.filter(
      (participation) => participation.event.id !== eventid
    );
    this.pastParticipations = {
      elements: this.pastParticipations.elements.filter(
        (participation) => participation.event.id !== eventid
      ),
      total: this.pastParticipations.total - 1,
    };
  }

  get hideCreateEventButton(): boolean {
    return !!this.config?.restrictions?.onlyGroupsCanCreateEvents;
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
@import "~bulma/sass/utilities/mixins.sass";

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
  .upcoming-month,
  .past-month {
    text-transform: capitalize;
    display: inline-block;
    position: relative;
    font-size: 1.3rem;

    &::after {
      background: $orange-3;
      position: absolute;
      left: 0;
      right: 0;
      top: 100%;
      content: "";
      width: calc(100% + 30px);
      height: 3px;
      max-width: 150px;
    }
  }
}

.not-found {
  margin-top: 2rem;
  .img-container {
    background-image: url("../../../public/img/pics/event_creation-480w.jpg");
    @media (min-resolution: 2dppx) {
      & {
        background-image: url("../../../public/img/pics/event_creation-1024w.jpg");
      }
    }

    &.webp {
      background-image: url("../../../public/img/pics/event_creation-480w.webp");
      @media (min-resolution: 2dppx) {
        & {
          background-image: url("../../../public/img/pics/event_creation-1024w.webp");
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

.wrapper {
  display: grid;
  grid-template-areas: "filter" "events";
  align-items: start;

  @include desktop {
    gap: 2rem;
    grid-template-columns: 1fr 3fr;
    grid-template-areas: "filter events";
  }

  .event-filter {
    grid-area: filter;
    background: lightgray;
    border-radius: 5px;
    padding: 0.75rem 1.25rem 0.25rem;

    @include desktop {
      padding: 2rem 1.25rem;
      ::v-deep .field.is-grouped {
        display: block;
      }
    }

    ::v-deep .field > .field {
      margin: 0 auto 1.25rem !important;
    }

    .date-filter ::v-deep .field-body {
      display: block;
    }
  }
  .my-events {
    grid-area: events;
  }
}
</style>
