<template>
  <div class="section container">
    <h1 class="title">{{ $t("Explore") }}</h1>
    <section v-if="tag">
      <i18n path="Events tagged with {tag}">
        <b-tag slot="tag" type="is-light">{{ $t("#{tag}", { tag }) }}</b-tag>
      </i18n>
    </section>
    <section class="hero is-light" v-else>
      <div class="hero-body">
        <form @submit.prevent="submit()">
          <b-field :label="$t('Key words')" label-for="search" expanded>
            <b-input
              icon="magnify"
              type="search"
              id="search"
              size="is-large"
              expanded
              v-model="search"
              :placeholder="$t('For instance: London, Taekwondo, Architecture…')"
            />
          </b-field>
          <b-field grouped group-multiline position="is-right" expanded>
            <b-field :label="$t('Location')" label-for="location">
              <address-auto-complete
                v-model="location"
                id="location"
                :placeholder="$t('For instance: London')"
              />
            </b-field>
            <b-field :label="$t('Radius')" label-for="radius">
              <b-select v-model="radius" id="radius">
                <option
                  v-for="(radiusOption, index) in radiusOptions"
                  :key="index"
                  :value="radiusOption"
                >
                  {{ radiusString(radiusOption) }}
                </option>
              </b-select>
            </b-field>
            <b-field :label="$t('Date')" label-for="date">
              <b-select v-model="when" id="date" :disabled="activeTab !== 0">
                <option v-for="(option, index) in options" :key="index" :value="option">
                  {{ option.label }}
                </option>
              </b-select>
            </b-field>
          </b-field>
        </form>
      </div>
    </section>
    <section class="events-featured" v-if="!tag && searchEvents.initial">
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <h2 class="title">{{ $t("Featured events") }}</h2>
      <div v-if="events.length > 0" class="columns is-multiline">
        <div class="column is-one-third-desktop" v-for="event in events" :key="event.uuid">
          <EventCard :event="event" />
        </div>
      </div>
      <b-message v-else-if="events.length === 0 && $apollo.loading === false" type="is-danger">{{
        $t("No events found")
      }}</b-message>
    </section>
    <b-tabs v-else v-model="activeTab" type="is-boxed" class="searchTabs">
      <b-tab-item>
        <template slot="header">
          <b-icon icon="calendar"></b-icon>
          <span>
            {{ $t("Events") }}
            <b-tag rounded>{{ searchEvents.total }}</b-tag>
          </span>
        </template>
        <div v-if="searchEvents.total > 0">
          <div class="columns is-multiline">
            <div
              class="column is-one-third-desktop"
              v-for="event in searchEvents.elements"
              :key="event.uuid"
            >
              <EventCard :event="event" />
            </div>
          </div>
          <div class="pagination">
            <b-pagination
              :total="searchEvents.total"
              v-model="eventPage"
              :per-page="EVENT_PAGE_LIMIT"
              :aria-next-label="$t('Next page')"
              :aria-previous-label="$t('Previous page')"
              :aria-page-label="$t('Page')"
              :aria-current-label="$t('Current page')"
            >
            </b-pagination>
          </div>
        </div>
        <b-message v-else-if="$apollo.loading === false" type="is-danger">{{
          $t("No events found")
        }}</b-message>
      </b-tab-item>
      <b-tab-item v-if="config && config.features.groups">
        <template slot="header">
          <b-icon icon="account-multiple"></b-icon>
          <span>
            {{ $t("Groups") }} <b-tag rounded>{{ searchGroups.total }}</b-tag>
          </span>
        </template>
        <div v-if="searchGroups.total > 0">
          <div class="columns is-multiline">
            <div
              class="column is-one-third-desktop"
              v-for="group in searchGroups.elements"
              :key="group.uuid"
            >
              <group-card :group="group" />
            </div>
          </div>
          <div class="pagination">
            <b-pagination
              :total="searchGroups.total"
              v-model="groupPage"
              :per-page="GROUP_PAGE_LIMIT"
              :aria-next-label="$t('Next page')"
              :aria-previous-label="$t('Previous page')"
              :aria-page-label="$t('Page')"
              :aria-current-label="$t('Current page')"
            >
            </b-pagination>
          </div>
        </div>
        <b-message v-else-if="$apollo.loading === false" type="is-danger">
          {{ $t("No groups found") }}
        </b-message>
      </b-tab-item>
    </b-tabs>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import ngeohash from "ngeohash";
import {
  endOfToday,
  addDays,
  startOfDay,
  endOfDay,
  endOfWeek,
  addWeeks,
  startOfWeek,
  endOfMonth,
  addMonths,
  startOfMonth,
  eachWeekendOfInterval,
} from "date-fns";
import EventCard from "../components/Event/EventCard.vue";
import { FETCH_EVENTS } from "../graphql/event";
import { IEvent } from "../types/event.model";
import RouteName from "../router/name";
import { IAddress, Address } from "../types/address.model";
import AddressAutoComplete from "../components/Event/AddressAutoComplete.vue";
import { SEARCH_EVENTS, SEARCH_GROUPS } from "../graphql/search";
import { Paginate } from "../types/paginate";
import { SearchTabs } from "../types/search.model";
import { IGroup } from "../types/actor";
import GroupCard from "../components/Group/GroupCard.vue";
import { CONFIG } from "../graphql/config";

interface ISearchTimeOption {
  label: string;
  start?: Date;
  end?: Date | null;
}

const tabsName: { events: number; groups: number } = {
  events: SearchTabs.EVENTS,
  groups: SearchTabs.GROUPS,
};

const EVENT_PAGE_LIMIT = 10;

const GROUP_PAGE_LIMIT = 10;

@Component({
  components: {
    EventCard,
    AddressAutoComplete,
    GroupCard,
  },
  apollo: {
    config: CONFIG,
    events: FETCH_EVENTS,
    searchEvents: {
      query: SEARCH_EVENTS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          term: this.search,
          tags: this.tag,
          location: this.geohash,
          beginsOn: this.start,
          endsOn: this.end,
          radius: this.radius,
          page: this.eventPage,
          limit: EVENT_PAGE_LIMIT,
        };
      },
      debounce: 300,
      skip() {
        return !this.search && !this.tag && !this.geohash && this.end === null;
      },
    },
    searchGroups: {
      query: SEARCH_GROUPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          term: this.search,
          location: this.geohash,
          radius: this.radius,
          page: this.groupPage,
          limit: GROUP_PAGE_LIMIT,
        };
      },
      skip() {
        return !this.search && !this.geohash;
      },
    },
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t("Explore events") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Search extends Vue {
  @Prop({ type: String, required: false }) tag!: string;

  events: IEvent[] = [];

  searchEvents: Paginate<IEvent> & { initial: boolean } = { total: 0, elements: [], initial: true };

  searchGroups: Paginate<IGroup> = { total: 0, elements: [] };

  eventPage = 1;

  groupPage = 1;

  search: string = (this.$route.query.term as string) || "";

  activeTab: SearchTabs = tabsName[this.$route.query.searchType as "events" | "groups"] || 0;

  location: IAddress = new Address();

  options: ISearchTimeOption[] = [
    {
      label: this.$t("Today") as string,
      start: new Date(),
      end: endOfToday(),
    },
    {
      label: this.$t("Tomorrow") as string,
      start: startOfDay(addDays(new Date(), 1)),
      end: endOfDay(addDays(new Date(), 1)),
    },
    {
      label: this.$t("This weekend") as string,
      start: this.weekend.start,
      end: this.weekend.end,
    },
    {
      label: this.$t("This week") as string,
      start: new Date(),
      end: endOfWeek(new Date(), { locale: this.$dateFnsLocale }),
    },
    {
      label: this.$t("Next week") as string,
      start: startOfWeek(addWeeks(new Date(), 1), { locale: this.$dateFnsLocale }),
      end: endOfWeek(addWeeks(new Date(), 1), { locale: this.$dateFnsLocale }),
    },
    {
      label: this.$t("This month") as string,
      start: new Date(),
      end: endOfMonth(new Date()),
    },
    {
      label: this.$t("Next month") as string,
      start: startOfMonth(addMonths(new Date(), 1)),
      end: endOfMonth(addMonths(new Date(), 1)),
    },
    {
      label: this.$t("Any day") as string,
      start: undefined,
      end: undefined,
    },
  ];

  when: ISearchTimeOption = {
    label: this.$t("Any day") as string,
    start: undefined,
    end: null,
  };

  EVENT_PAGE_LIMIT = EVENT_PAGE_LIMIT;

  GROUP_PAGE_LIMIT = GROUP_PAGE_LIMIT;

  radiusString = (radius: number | null): string => {
    if (radius) {
      return this.$tc("{nb} km", radius, { nb: radius }) as string;
    }
    return this.$t("any distance") as string;
  };

  radiusOptions: (number | null)[] = [1, 5, 10, 25, 50, 100, 150, null];

  radius = 50;

  submit(): void {
    this.$apollo.queries.searchEvents.refetch();
  }

  @Watch("search")
  updateSearchTerm(): void {
    this.$router.push({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, term: this.search },
    });
  }

  @Watch("activeTab")
  updateActiveTab(): void {
    const searchType = this.activeTab === tabsName.events ? "events" : "groups";
    this.$router.push({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, searchType },
    });
  }

  get weekend(): { start: Date; end: Date } {
    const now = new Date();
    const endOfWeekDate = endOfWeek(now, { locale: this.$dateFnsLocale });
    const startOfWeekDate = startOfWeek(now, { locale: this.$dateFnsLocale });
    const [start, end] = eachWeekendOfInterval({ start: startOfWeekDate, end: endOfWeekDate });
    return { start: startOfDay(start), end: endOfDay(end) };
  }

  get geohash(): string | undefined {
    if (this.location && this.location.geom) {
      const [lon, lat] = this.location.geom.split(";");
      return ngeohash.encode(lat, lon, 6);
    }
    return undefined;
  }

  get start(): Date | undefined {
    return this.when.start;
  }

  get end(): Date | undefined | null {
    return this.when.end;
  }
}
</script>

<style scoped lang="scss">
main > .container {
  background: $white;

  .hero-body {
    padding: 1rem 1.5rem;
  }
}

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

form {
  ::v-deep .field label.label {
    margin-bottom: 0;
  }
}
</style>
