<template>
  <div id="homepage">
    <section
      class="hero"
      :class="{ webp: supportsWebPFormat }"
      v-if="config && (!currentUser.id || !currentActor.id)"
    >
      <div class="hero-body">
        <div class="container">
          <h1 class="title">
            {{ config.slogan || $t("Gather ⋅ Organize ⋅ Mobilize") }}
          </h1>
          <p
            v-html="
              $t('Join <b>{instance}</b>, a Mobilizon instance', {
                instance: config.name,
              })
            "
          />
          <p class="instance-description">{{ config.description }}</p>
          <!-- We don't invite to find other instances yet -->
          <!-- <p v-if="!config.registrationsOpen">
              {{ $t("This instance isn't opened to registrations, but you can register on other instances.") }}
          </p>-->
          <b-message type="is-danger" v-if="!config.registrationsOpen">{{
            $t("Unfortunately, this instance isn't opened to registrations")
          }}</b-message>
          <div class="buttons">
            <b-button
              type="is-primary"
              tag="router-link"
              :to="{ name: RouteName.REGISTER }"
              v-if="config.registrationsOpen"
              >{{ $t("Create an account") }}</b-button
            >
            <!-- We don't invite to find other instances yet -->
            <!-- <b-button v-else type="is-link" tag="a" href="https://joinmastodon.org">{{ $t('Find an instance') }}</b-button> -->
            <b-button
              type="is-text"
              tag="router-link"
              :to="{ name: RouteName.ABOUT }"
            >
              {{ $t("Learn more about {instance}", { instance: config.name }) }}
            </b-button>
          </div>
        </div>
      </div>
    </section>
    <div
      id="featured_events"
      class="container section"
      v-if="config && (!currentUser.id || !currentActor.id)"
    >
      <section class="events-featured">
        <h2 class="title">{{ $t("Featured events") }}</h2>
        <b-loading :active.sync="$apollo.loading" />
        <div
          v-if="filteredFeaturedEvents.length > 0"
          class="columns is-multiline"
        >
          <div
            class="column is-one-third-desktop"
            v-for="event in filteredFeaturedEvents.slice(0, 6)"
            :key="event.uuid"
          >
            <EventCard :event="event" />
          </div>
        </div>
        <b-message v-else type="is-danger">{{
          $t("No events found")
        }}</b-message>
      </section>
    </div>
    <div id="picture" v-if="config && (!currentUser.id || !currentActor.id)">
      <div class="picture-container">
        <picture>
          <source
            media="(max-width: 799px)"
            srcset="/img/pics/homepage-480w.webp"
            type="image/webp"
          />
          <source
            media="(max-width: 799px)"
            srcset="/img/pics/homepage-480w.jpg"
            type="image/jpeg"
          />

          <source
            media="(max-width: 1024px)"
            srcset="/img/pics/homepage-1024w.webp"
            type="image/webp"
          />
          <source
            media="(max-width: 1024px)"
            srcset="/img/pics/homepage-1024w.jpg"
            type="image/jpeg"
          />

          <source
            media="(max-width: 1920px)"
            srcset="/img/pics/homepage-1920w.webp"
            type="image/webp"
          />
          <source
            media="(max-width: 1920px)"
            srcset="/img/pics/homepage-1920w.jpg"
            type="image/jpeg"
          />

          <source
            media="(min-width: 1921px)"
            srcset="/img/pics/homepage.webp"
            type="image/webp"
          />
          <source
            media="(min-width: 1921px)"
            srcset="/img/pics/homepage.jpg"
            type="image/jpeg"
          />

          <img
            src="/img/pics/homepage-1024w.jpg"
            width="3840"
            height="2719"
            alt=""
            loading="lazy"
          />
        </picture>
      </div>
      <div class="container section">
        <div class="columns">
          <div class="column">
            <h3 class="title">{{ $t("A practical tool") }}</h3>
            <p
              v-html="
                $t(
                  'Mobilizon is a tool that helps you <b>find, create and organise events</b>.'
                )
              "
            />
          </div>
          <div class="column">
            <h3 class="title">{{ $t("An ethical alternative") }}</h3>
            <p
              v-html="
                $t(
                  'Ethical alternative to Facebook events, groups and pages, Mobilizon is a <b>tool designed to serve you</b>. Period.'
                )
              "
            />
          </div>
          <div class="column">
            <h3 class="title">{{ $t("A federated software") }}</h3>
            <p
              v-html="
                $t(
                  'Mobilizon is not a giant platform, but a <b>multitude of interconnected Mobilizon websites</b>.'
                )
              "
            />
          </div>
        </div>
        <div class="buttons">
          <a
            class="button is-primary is-large"
            href="https://joinmobilizon.org"
            >{{ $t("Learn more about Mobilizon") }}</a
          >
        </div>
      </div>
    </div>
    <div
      class="container section"
      v-if="config && loggedUser && loggedUser.settings"
    >
      <section v-if="currentActor.id">
        <b-message type="is-info" v-if="welcomeBack">{{
          $t("Welcome back {username}!", {
            username: currentActor.displayName(),
          })
        }}</b-message>
        <b-message type="is-info" v-if="newRegisteredUser">{{
          $t("Welcome to Mobilizon, {username}!", {
            username: currentActor.displayName(),
          })
        }}</b-message>
      </section>
      <section
        v-if="currentActor.id && goingToEvents.size > 0"
        class="container"
      >
        <h3 class="title">{{ $t("Upcoming") }}</h3>
        <b-loading :active.sync="$apollo.loading" />
        <div v-for="row of goingToEvents" class="upcoming-events" :key="row[0]">
          <span
            class="date-component-container"
            v-if="isInLessThanSevenDays(row[0])"
          >
            <date-component :date="row[0]" />
            <subtitle v-if="isToday(row[0])">{{
              $tc("You have one event today.", row[1].length, {
                count: row[1].length,
              })
            }}</subtitle>
            <subtitle v-else-if="isTomorrow(row[0])">{{
              $tc("You have one event tomorrow.", row[1].length, {
                count: row[1].length,
              })
            }}</subtitle>
            <subtitle v-else-if="isInLessThanSevenDays(row[0])">
              {{
                $tc("You have one event in {days} days.", row[1].length, {
                  count: row[1].length,
                  days: calculateDiffDays(row[0]),
                })
              }}
            </subtitle>
          </span>
          <div>
            <EventListCard
              v-for="participation in thisWeek(row)"
              @event-deleted="eventDeleted"
              :key="participation[1].id"
              :participation="participation[1]"
            />
          </div>
        </div>
        <span class="view-all">
          <router-link :to="{ name: RouteName.MY_EVENTS }"
            >{{ $t("View everything") }} >></router-link
          >
        </span>
      </section>
      <section v-if="currentActor && lastWeekEvents.length > 0">
        <h3 class="title">{{ $t("Last week") }}</h3>
        <b-loading :active.sync="$apollo.loading" />
        <div>
          <EventListCard
            v-for="participation in lastWeekEvents"
            :key="participation.id"
            :participation="participation"
            @event-deleted="eventDeleted"
            :options="{ hideDate: false }"
          />
        </div>
      </section>
      <section class="events-featured">
        <h2 class="title">{{ $t("Featured events") }}</h2>
        <b-loading :active.sync="$apollo.loading" />
        <div
          v-if="filteredFeaturedEvents.length > 0"
          class="columns is-multiline"
        >
          <div
            class="column is-one-third-desktop"
            v-for="event in filteredFeaturedEvents.slice(0, 6)"
            :key="event.uuid"
          >
            <EventCard :event="event" />
          </div>
        </div>
        <b-message v-else type="is-danger"
          >{{ $t("No events found") }}<br />
          <div v-if="goingToEvents.size > 0 || lastWeekEvents.length > 0">
            <b-icon size="is-small" icon="information-outline" />
            <small>{{
              $t("The events you created are not shown here.")
            }}</small>
          </div>
        </b-message>
      </section>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { ParticipantRole } from "@/types/enums";
import { Paginate } from "@/types/paginate";
import { supportsWebPFormat } from "@/utils/support";
import { IParticipant, Participant } from "../types/participant.model";
import { FETCH_EVENTS } from "../graphql/event";
import EventListCard from "../components/Event/EventListCard.vue";
import EventCard from "../components/Event/EventCard.vue";
import {
  CURRENT_ACTOR_CLIENT,
  LOGGED_USER_PARTICIPATIONS,
} from "../graphql/actor";
import { IPerson, Person } from "../types/actor";
import { ICurrentUser, IUser } from "../types/current-user.model";
import { CURRENT_USER_CLIENT, USER_SETTINGS } from "../graphql/user";
import RouteName from "../router/name";
import { IEvent } from "../types/event.model";
import DateComponent from "../components/Event/DateCalendarIcon.vue";
import { CONFIG } from "../graphql/config";
import { IConfig } from "../types/config.model";
import Subtitle from "../components/Utils/Subtitle.vue";

@Component({
  apollo: {
    events: {
      query: FETCH_EVENTS,
      fetchPolicy: "no-cache", // Debug me: https://github.com/apollographql/apollo-client/issues/3030
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
      update: (data) => new Person(data.currentActor),
    },
    currentUser: CURRENT_USER_CLIENT,
    loggedUser: {
      query: USER_SETTINGS,
      fetchPolicy: "no-cache",
      error() {
        return null;
      },
    },
    config: CONFIG,
    currentUserParticipations: {
      query: LOGGED_USER_PARTICIPATIONS,
      fetchPolicy: "cache-and-network",
      variables() {
        const lastWeek = new Date();
        lastWeek.setDate(new Date().getDate() - 7);
        return {
          afterDateTime: lastWeek.toISOString(),
        };
      },
      update: (data) =>
        data.loggedUser.participations.elements.map(
          (participation: IParticipant) => new Participant(participation)
        ),
      skip() {
        return this.currentUser.isLoggedIn === false;
      },
    },
  },
  components: {
    Subtitle,
    DateComponent,
    EventListCard,
    EventCard,
    "settings-onboard": () => import("./User/SettingsOnboard.vue"),
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.instanceName,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Home extends Vue {
  events: Paginate<IEvent> = {
    elements: [],
    total: 0,
  };

  locations = [];

  city = { name: null };

  country = { name: null };

  currentUser!: ICurrentUser;

  loggedUser!: ICurrentUser;

  currentActor!: IPerson;

  config!: IConfig;

  RouteName = RouteName;

  currentUserParticipations: IParticipant[] = [];

  supportsWebPFormat = supportsWebPFormat;

  // get displayed_name() {
  //   return this.loggedPerson && this.loggedPerson.name === null
  //     ? this.loggedPerson.preferredUsername
  //     : this.loggedPerson.name;
  // }

  get instanceName(): string | undefined {
    if (!this.config) return undefined;
    return this.config.name;
  }

  // eslint-disable-next-line class-methods-use-this
  get welcomeBack(): boolean {
    return window.localStorage.getItem("welcome-back") === "yes";
  }

  // eslint-disable-next-line class-methods-use-this
  get newRegisteredUser(): boolean {
    return window.localStorage.getItem("new-registered-user") === "yes";
  }

  thisWeek(
    row: [string, Map<string, IParticipant>]
  ): Map<string, IParticipant> {
    if (this.isInLessThanSevenDays(row[0])) {
      return row[1];
    }
    return new Map();
  }

  // eslint-disable-next-line class-methods-use-this
  mounted(): void {
    if (window.localStorage.getItem("welcome-back")) {
      window.localStorage.removeItem("welcome-back");
    }
    if (window.localStorage.getItem("new-registered-user")) {
      window.localStorage.removeItem("new-registered-user");
    }
  }

  // eslint-disable-next-line class-methods-use-this
  isToday(date: Date): boolean {
    return new Date(date).toDateString() === new Date().toDateString();
  }

  isTomorrow(date: string): boolean {
    return this.isInDays(date, 1);
  }

  isInDays(date: string, nbDays: number): boolean {
    return this.calculateDiffDays(date) === nbDays;
  }

  isBefore(date: string, nbDays: number): boolean {
    return this.calculateDiffDays(date) < nbDays;
  }

  isAfter(date: string, nbDays: number): boolean {
    return this.calculateDiffDays(date) >= nbDays;
  }

  isInLessThanSevenDays(date: string): boolean {
    return this.isBefore(date, 7);
  }

  // eslint-disable-next-line class-methods-use-this
  calculateDiffDays(date: string): number {
    return Math.ceil(
      (new Date(date).getTime() - new Date().getTime()) / 1000 / 60 / 60 / 24
    );
  }

  get thisWeekGoingToEvents(): IParticipant[] {
    const res = this.currentUserParticipations.filter(
      ({ event, role }) =>
        event.beginsOn != null &&
        this.isAfter(event.beginsOn.toDateString(), 0) &&
        this.isBefore(event.beginsOn.toDateString(), 7) &&
        role !== ParticipantRole.REJECTED
    );
    res.sort(
      (a: IParticipant, b: IParticipant) =>
        a.event.beginsOn.getTime() - b.event.beginsOn.getTime()
    );
    return res;
  }

  get goingToEvents(): Map<string, Map<string, IParticipant>> {
    return this.thisWeekGoingToEvents.reduce(
      (
        acc: Map<string, Map<string, IParticipant>>,
        participation: IParticipant
      ) => {
        const day = new Date(participation.event.beginsOn).toDateString();
        const participations: Map<string, IParticipant> =
          acc.get(day) || new Map();
        participations.set(
          `${participation.event.uuid}${participation.actor.id}`,
          participation
        );
        acc.set(day, participations);
        return acc;
      },
      new Map()
    );
  }

  get lastWeekEvents(): IParticipant[] {
    const res = this.currentUserParticipations.filter(
      ({ event, role }) =>
        event.beginsOn != null &&
        this.isBefore(event.beginsOn.toDateString(), 0) &&
        role !== ParticipantRole.REJECTED
    );
    res.sort(
      (a: IParticipant, b: IParticipant) =>
        a.event.beginsOn.getTime() - b.event.beginsOn.getTime()
    );
    return res;
  }

  /**
   * Return all events from server excluding the ones shown as participating
   */
  get filteredFeaturedEvents(): IEvent[] {
    return this.events.elements.filter(
      ({ id }) =>
        !this.thisWeekGoingToEvents
          .filter(
            (participation) => participation.role === ParticipantRole.CREATOR
          )
          .map(({ event: { id: eventId } }) => eventId)
          .includes(id)
    );
  }

  eventDeleted(eventid: string): void {
    this.currentUserParticipations = this.currentUserParticipations.filter(
      (participation) => participation.event.id !== eventid
    );
  }

  viewEvent(event: IEvent): void {
    this.$router.push({ name: RouteName.EVENT, params: { uuid: event.uuid } });
  }

  @Watch("loggedUser")
  detectEmptyUserSettings(loggedUser: IUser): void {
    if (loggedUser && loggedUser.id && loggedUser.settings === null) {
      this.$router.push({
        name: RouteName.WELCOME_SCREEN,
        params: { step: "1" },
      });
    }
  }
}
</script>

<style lang="scss" scoped>
@import "~bulma/sass/utilities/mixins.sass";

main > div > .container {
  background: $white;
  padding: 1rem 1.5rem 3rem;
}

.search-autocomplete {
  border: 1px solid #dbdbdb;
  color: rgba(0, 0, 0, 0.87);
}

.events-featured {
  & > h3 {
    padding-left: 0.75rem;
  }

  .columns {
    margin: 1rem auto 3rem;
  }
}

.date-component-container {
  display: flex;
  align-items: center;
  margin: 1.5rem auto;

  h3.subtitle {
    margin-left: 7px;
  }
}

section.container {
  margin: auto auto 3rem;
}

span.view-all {
  display: block;
  margin-top: 2rem;
  text-align: right;

  a {
    text-decoration: underline;
  }
}

section.hero {
  position: relative;
  z-index: 1;

  &::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    opacity: 0.3;
    z-index: -1;
    background: url("/img/pics/homepage_background-1024w.png");
    background-size: cover;
  }
  &.webp::before {
    background-image: url("/img/pics/homepage_background-1024w.webp");
  }

  & > .hero-body {
    padding: 1rem 1.5rem 3rem;
  }

  .title {
    color: $background-color;
  }

  .column figure.image img {
    max-width: 400px;
  }

  .instance-description {
    margin-bottom: 1rem;
  }
}

#featured_events {
  padding: 1rem 0;
  min-height: calc(100vh - 400px);
  z-index: 10;

  .title {
    margin: 20px auto 0;
  }

  .columns {
    margin: 0rem auto 3rem;
  }
}

#picture {
  .picture-container {
    position: relative;
    &::before {
      content: "";
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: linear-gradient(
        0deg,
        $white 0,
        rgba(0, 0, 0, 0) 5%,
        rgba(0, 0, 0, 0) 90%,
        $white 100%
      );
      z-index: 1;
    }

    & > img {
      object-fit: cover;
      max-height: 80vh;
      display: block;
      margin: auto;
      width: 100%;
    }
  }

  .container.section {
    background: $white;

    @include tablet {
      margin-top: -4rem;
    }
    z-index: 10;

    .title {
      margin: 0 0 10px;
      font-size: 30px;
    }

    .buttons {
      justify-content: center;
      margin-top: 2rem;
    }
  }
}

#homepage {
  background: $white;
}
</style>
