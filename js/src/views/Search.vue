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
          <b-field
            class="searchQuery"
            :label="$t('Key words')"
            label-for="search"
          >
            <b-input
              icon="magnify"
              type="search"
              id="search"
              :value="search"
              @input="debouncedUpdateSearchQuery"
              :placeholder="
                $t('For instance: London, Taekwondo, Architecture…')
              "
            />
          </b-field>
          <full-address-auto-complete
            class="searchLocation"
            :label="$t('Location')"
            v-model="location"
            id="location"
            ref="aac"
            :placeholder="$t('For instance: London')"
            @input="locchange"
          />
          <b-field
            :label="$t('Radius')"
            label-for="radius"
            class="searchRadius"
          >
            <b-select expanded v-model="radius" id="radius">
              <option
                v-for="(radiusOption, index) in radiusOptions"
                :key="index"
                :value="radiusOption"
              >
                {{ radiusString(radiusOption) }}
              </option>
            </b-select>
          </b-field>
          <b-field :label="$t('Date')" label-for="date" class="searchDate">
            <b-select
              expanded
              v-model="when"
              id="date"
              :disabled="activeTab !== 0"
            >
              <option
                v-for="(option, index) in dateOptions"
                :key="index"
                :value="index"
              >
                {{ option.label }}
              </option>
            </b-select>
          </b-field>
          <b-field
            expanded
            :label="$t('Type')"
            label-for="type"
            class="searchType"
          >
            <b-select
              expanded
              v-model="type"
              id="type"
              :disabled="activeTab !== 0"
            >
              <option :value="null">
                {{ $t("Any type") }}
              </option>
              <option :value="'ONLINE'">
                {{ $t("Online") }}
              </option>
              <option :value="'IN_PERSON'">
                {{ $t("In person") }}
              </option>
            </b-select>
          </b-field>
        </form>
      </div>
    </section>
    <section
      class="events-featured"
      v-if="!canSearchEvents && !canSearchGroups"
    >
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <h2 class="title">{{ $t("Featured events") }}</h2>
      <div v-if="events.elements.length > 0">
        <multi-card :events="events.elements" />
        <div class="pagination" v-if="events.total > EVENT_PAGE_LIMIT">
          <b-pagination
            :total="events.total"
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
      <b-message
        v-else-if="events.elements.length === 0 && $apollo.loading === false"
        type="is-danger"
        >{{ $t("No events found") }}</b-message
      >
    </section>
    <b-tabs v-else v-model="activeTab" type="is-boxed" class="mt-3 searchTabs">
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <b-tab-item>
        <template slot="header">
          <b-icon icon="calendar"></b-icon>
          <span>
            {{ $t("Events") }}
            <b-tag rounded>{{ searchEvents.total }}</b-tag>
          </span>
        </template>
        <div v-if="searchEvents.total > 0">
          <multi-card class="my-4" :events="searchEvents.elements" />
          <div class="pagination" v-if="searchEvents.total > EVENT_PAGE_LIMIT">
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
      <b-tab-item v-if="!tag">
        <template slot="header">
          <b-icon icon="account-multiple"></b-icon>
          <span>
            {{ $t("Groups") }} <b-tag rounded>{{ searchGroups.total }}</b-tag>
          </span>
        </template>
        <b-message v-if="config && !config.features.groups" type="is-danger">
          {{ $t("Groups are not enabled on this instance.") }}
        </b-message>
        <div v-else-if="searchGroups.total > 0">
          <multi-group-card class="my-4" :groups="searchGroups.elements" />
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
import { Component, Prop, Vue } from "vue-property-decorator";
import ngeohash, { GeographicPoint } from "ngeohash";
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
import { SearchTabs } from "@/types/enums";
import MultiCard from "../components/Event/MultiCard.vue";
import { FETCH_EVENTS } from "../graphql/event";
import { EventType, IEvent } from "../types/event.model";
import RouteName from "../router/name";
import { IAddress, Address } from "../types/address.model";
import FullAddressAutoComplete from "../components/Event/FullAddressAutoComplete.vue";
import { SEARCH_EVENTS_AND_GROUPS } from "../graphql/search";
import { Paginate } from "../types/paginate";
import { IGroup } from "../types/actor";
import MultiGroupCard from "../components/Group/MultiGroupCard.vue";
import { CONFIG } from "../graphql/config";
import { REVERSE_GEOCODE } from "../graphql/address";
import debounce from "lodash/debounce";

interface ISearchTimeOption {
  label: string;
  start?: Date | null;
  end?: Date | null;
}

const EVENT_PAGE_LIMIT = 12;

const GROUP_PAGE_LIMIT = 12;

const DEFAULT_RADIUS = 25; // value to set if radius is null but location set

const DEFAULT_ZOOM = 11; // zoom on a city

const GEOHASH_DEPTH = 9; // put enough accuracy, radius will be used anyway

@Component({
  components: {
    MultiCard,
    FullAddressAutoComplete,
    MultiGroupCard,
  },
  apollo: {
    config: CONFIG,
    events: {
      query: FETCH_EVENTS,
      variables() {
        return {
          page: this.eventPage,
          limit: EVENT_PAGE_LIMIT,
        };
      },
    },
    searchElements: {
      query: SEARCH_EVENTS_AND_GROUPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          term: this.search,
          tags: this.tag,
          location: this.geohash,
          beginsOn: this.start,
          endsOn: this.end,
          radius: this.radius,
          eventPage: this.eventPage,
          groupPage: this.groupPage,
          limit: EVENT_PAGE_LIMIT,
          type: this.type,
        };
      },
      update(data) {
        this.searchEvents = data.searchEvents;
        this.searchGroups = data.searchGroups;
      },
    },
  },
  metaInfo() {
    return {
      title: this.$t("Explore events") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Search extends Vue {
  @Prop({ type: String, required: false }) tag!: string;

  events: Paginate<IEvent> = {
    total: 0,
    elements: [],
  };

  searchEvents: Paginate<IEvent> = {
    total: 0,
    elements: [],
  };

  searchGroups: Paginate<IGroup> = { total: 0, elements: [] };

  location: IAddress = new Address();

  dateOptions: Record<string, ISearchTimeOption> = {
    past: {
      label: this.$t("In the past") as string,
      start: null,
      end: new Date(),
    },
    today: {
      label: this.$t("Today") as string,
      start: new Date(),
      end: endOfToday(),
    },
    tomorrow: {
      label: this.$t("Tomorrow") as string,
      start: startOfDay(addDays(new Date(), 1)),
      end: endOfDay(addDays(new Date(), 1)),
    },
    weekend: {
      label: this.$t("This weekend") as string,
      start: this.weekend.start,
      end: this.weekend.end,
    },
    week: {
      label: this.$t("This week") as string,
      start: new Date(),
      end: endOfWeek(new Date(), { locale: this.$dateFnsLocale }),
    },
    next_week: {
      label: this.$t("Next week") as string,
      start: startOfWeek(addWeeks(new Date(), 1), {
        locale: this.$dateFnsLocale,
      }),
      end: endOfWeek(addWeeks(new Date(), 1), { locale: this.$dateFnsLocale }),
    },
    month: {
      label: this.$t("This month") as string,
      start: new Date(),
      end: endOfMonth(new Date()),
    },
    next_month: {
      label: this.$t("Next month") as string,
      start: startOfMonth(addMonths(new Date(), 1)),
      end: endOfMonth(addMonths(new Date(), 1)),
    },
    any: {
      label: this.$t("Any day") as string,
      start: undefined,
      end: undefined,
    },
  };

  EVENT_PAGE_LIMIT = EVENT_PAGE_LIMIT;

  GROUP_PAGE_LIMIT = GROUP_PAGE_LIMIT;

  $refs!: {
    aac: FullAddressAutoComplete;
  };

  data(): Record<string, unknown> {
    return {
      debouncedUpdateSearchQuery: debounce(this.updateSearchQuery, 500),
    };
  }

  mounted(): void {
    this.prepareLocation(this.$route.query.geohash as string);
  }

  radiusString = (radius: number | null): string => {
    if (radius) {
      return this.$tc("{nb} km", radius, { nb: radius }) as string;
    }
    return this.$t("any distance") as string;
  };

  radiusOptions: (number | null)[] = [1, 5, 10, 25, 50, 100, 150, null];

  submit(): void {
    this.$apollo.queries.searchEvents.refetch();
  }

  updateSearchQuery(searchQuery: string): void {
    this.search = searchQuery;
  }

  get eventPage(): number {
    return parseInt(this.$route.query.eventPage as string, 10) || 1;
  }

  set eventPage(page: number) {
    this.$router.push({
      name: this.$route.name || RouteName.SEARCH,
      query: { ...this.$route.query, eventPage: page.toString() },
    });
  }

  get groupPage(): number {
    return parseInt(this.$route.query.groupPage as string, 10) || 1;
  }

  set groupPage(page: number) {
    this.$router.push({
      name: this.$route.name || RouteName.SEARCH,
      query: { ...this.$route.query, groupPage: page.toString() },
    });
  }

  get search(): string | undefined {
    return this.$route.query.term as string;
  }

  set search(term: string | undefined) {
    this.$router.replace({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, term },
    });
  }

  get activeTab(): SearchTabs {
    return (
      parseInt(this.$route.query.searchType as string, 10) || SearchTabs.EVENTS
    );
  }

  set activeTab(value: SearchTabs) {
    this.$router.replace({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, searchType: value.toString() },
    });
  }

  get geohash(): string | undefined {
    if (this.location?.geom) {
      const [lon, lat] = this.location.geom.split(";");
      return ngeohash.encode(lat, lon, GEOHASH_DEPTH);
    }
    return undefined;
  }

  set geohash(value: string | undefined) {
    this.$router.replace({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, geohash: value },
    });
  }

  get radius(): number | null {
    if (this.$route.query.radius === "any") {
      return null;
    }
    return parseInt(this.$route.query.radius as string, 10) || null;
  }

  set radius(value: number | null) {
    const radius = value === null ? "any" : value.toString();
    this.$router.replace({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, radius },
    });
  }

  get when(): string {
    return (this.$route.query.when as string) || "any";
  }

  set when(value: string) {
    this.$router.replace({
      name: RouteName.SEARCH,
      query: { ...this.$route.query, when: value },
    });
  }

  get type(): EventType {
    return this.$route.query.type as EventType;
  }

  set type(type: EventType) {
    const query = { ...this.$route.query, type };
    if (type == null) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      delete query.type;
    }
    this.$router.replace({
      name: RouteName.SEARCH,
      query,
    });
  }

  get weekend(): { start: Date; end: Date } {
    const now = new Date();
    const endOfWeekDate = endOfWeek(now, { locale: this.$dateFnsLocale });
    const startOfWeekDate = startOfWeek(now, { locale: this.$dateFnsLocale });
    const [start, end] = eachWeekendOfInterval({
      start: startOfWeekDate,
      end: endOfWeekDate,
    });
    return { start: startOfDay(start), end: endOfDay(end) };
  }

  private prepareLocation(value: string | undefined): void {
    if (value !== undefined) {
      // decode
      const latlon = ngeohash.decode(value);
      // set location
      this.reverseGeoCode(latlon, DEFAULT_ZOOM);
    }
  }

  async reverseGeoCode(e: GeographicPoint, zoom: number): Promise<void> {
    const result = await this.$apollo.query({
      query: REVERSE_GEOCODE,
      variables: {
        latitude: e.latitude,
        longitude: e.longitude,
        zoom,
        locale: this.$i18n.locale,
      },
    });
    const addressData = result.data.reverseGeocode.map(
      (address: IAddress) => new Address(address)
    );
    if (addressData.length > 0) {
      this.location = addressData[0];
    }
  }

  locchange = (e: IAddress): void => {
    if (this.radius === undefined || this.radius === null) {
      this.radius = DEFAULT_RADIUS;
    }
    if (e?.geom) {
      const [lon, lat] = e.geom.split(";");
      this.geohash = ngeohash.encode(lat, lon, GEOHASH_DEPTH);
    } else {
      this.geohash = undefined;
    }
  };

  get start(): Date | undefined | null {
    if (this.dateOptions[this.when]) {
      return this.dateOptions[this.when].start;
    }
    return undefined;
  }

  get end(): Date | undefined | null {
    if (this.dateOptions[this.when]) {
      return this.dateOptions[this.when].end;
    }
    return undefined;
  }

  get canSearchGroups(): boolean {
    return (
      this.stringExists(this.search) ||
      (this.stringExists(this.geohash) && this.valueExists(this.radius))
    );
  }

  get canSearchEvents(): boolean {
    return (
      this.stringExists(this.search) ||
      this.stringExists(this.tag) ||
      this.stringExists(this.type) ||
      (this.stringExists(this.geohash) && this.valueExists(this.radius)) ||
      this.valueExists(this.end)
    );
  }

  // helper functions for skip
  private valueExists(value: any): boolean {
    return value !== undefined && value !== null;
  }

  private stringExists(value: string | null | undefined): boolean {
    return this.valueExists(value) && (value as string).length > 0;
  }
}
</script>

<style scoped lang="scss">
@import "~bulma/sass/utilities/mixins.sass";
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
  // ::v-deep .field label.label {
  //   margin-bottom: 0;
  // }

  // .field.is-expanded:last-child > .field-body > .field.is-grouped {
  //   flex-wrap: wrap;
  //   flex: 1;
  //   .field {
  //     flex: 1 0 auto;
  //     &:first-child {
  //       flex: 3 0 300px;
  //     }
  //   }
  // }
  display: grid;
  grid-gap: 0 15px;
  grid-template-areas: "query" "location" "radius" "date" "type";

  & > * {
    margin-bottom: 0 !important;
  }

  @include tablet {
    grid-template-columns: max-content max-content max-content auto;
    grid-template-areas: "query . ." "location . ." "radius date type";
  }

  @include desktop {
    grid-template-columns: max-content max-content max-content 1fr 3fr;
    grid-template-areas: "query . location" "radius date type";
  }

  .searchQuery {
    grid-area: query;
    @include tablet {
      grid-column: span 4;
    }
    @include desktop {
      grid-column-start: 1;
      grid-column-end: 4;
    }
  }

  .searchLocation {
    grid-area: location;
    :v-deep .column {
      padding-bottom: 0;
    }
    @include tablet {
      grid-column: span 4;
    }
    @include desktop {
      grid-column-start: 4;
      grid-column-end: 7;
    }
  }

  .searchRadius {
    grid-area: radius;
  }

  .searchDate {
    grid-area: date;
  }

  .searchType {
    grid-area: type;
  }
}
</style>
