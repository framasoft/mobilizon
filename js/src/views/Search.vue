<template>
  <section class="container">
    <form @submit.prevent="processSearch" v-if="!actualTag">
      <b-field :label="$t('Event')">
        <b-input size="is-large" v-model="search" />
      </b-field>
      <b-field :label="$t('Location')">
        <address-auto-complete v-model="location" />
      </b-field>
      <b-button native-type="submit">{{ $t("Go") }}</b-button>
    </form>
    <b-loading :active.sync="$apollo.loading" />
    <b-tabs v-model="activeTab" type="is-boxed" class="searchTabs" @change="changeTab">
      <b-tab-item>
        <template slot="header">
          <b-icon icon="calendar"></b-icon>
          <span>
            {{ $t("Events") }}
            <b-tag rounded>{{ searchEvents.total }}</b-tag>
          </span>
        </template>
        <div v-if="searchEvents.total > 0" class="columns is-multiline">
          <div
            class="column is-one-quarter-desktop"
            v-for="event in searchEvents.elements"
            :key="event.uuid"
          >
            <EventCard :event="event" />
          </div>
        </div>
        <b-message v-else-if="$apollo.loading === false" type="is-danger">{{
          $t("No events found")
        }}</b-message>
      </b-tab-item>
      <!--            <b-tab-item>-->
      <!--                <template slot="header">-->
      <!--                    <b-icon icon="account-multiple"></b-icon>-->
      <!--                    <span>-->
      <!--                        {{ $t('Groups') }} <b-tag rounded>{{ searchGroups.total }}</b-tag>-->
      <!--                    </span>-->
      <!--                </template>-->
      <!--                <div v-if="searchGroups.total > 0" class="columns is-multiline">-->
      <!--                    <div class="column is-one-quarter-desktop is-half-mobile"-->
      <!--                         v-for="group in groups"-->
      <!--                         :key="group.uuid">-->
      <!--                        <group-card :group="group" />-->
      <!--                    </div>-->
      <!--                </div>-->
      <!--                <b-message v-else-if="$apollo.loading === false" type="is-danger">-->
      <!--                    {{ $t('No groups found') }}-->
      <!--                </b-message>-->
      <!--            </b-tab-item>-->
    </b-tabs>
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { SEARCH_EVENTS, SEARCH_GROUPS } from "../graphql/search";
import RouteName from "../router/name";
import EventCard from "../components/Event/EventCard.vue";
import GroupCard from "../components/Group/GroupCard.vue";
import AddressAutoComplete from "../components/Event/AddressAutoComplete.vue";
import { Group, IGroup } from "../types/actor";
import { IAddress, Address } from "../types/address.model";
import { SearchEvent, SearchGroup } from "../types/search.model";
import ngeohash from "ngeohash";

enum SearchTabs {
  EVENTS = 0,
  GROUPS = 1,
  PERSONS = 2, // not used right now
}

const tabsName: { events: number; groups: number } = {
  events: SearchTabs.EVENTS,
  groups: SearchTabs.GROUPS,
};

@Component({
  apollo: {
    searchEvents: {
      query: SEARCH_EVENTS,
      variables() {
        return {
          term: this.search,
          tag: this.actualTag,
          location: this.geohash,
        };
      },
      skip() {
        return !this.search && !this.actualTag;
      },
    },
    searchGroups: {
      query: SEARCH_GROUPS,
      variables() {
        return {
          searchText: this.search,
        };
      },
      skip() {
        return !this.search || this.isURL(this.search);
      },
    },
  },
  components: {
    GroupCard,
    EventCard,
    AddressAutoComplete,
  },
})
export default class Search extends Vue {
  @Prop({ type: String, required: false }) searchTerm!: string;

  @Prop({ type: String, required: false }) tag!: string;

  @Prop({ type: String, required: false, default: "events" }) searchType!: "events" | "groups";

  searchEvents: SearchEvent = { total: 0, elements: [] };

  searchGroups: SearchGroup = { total: 0, elements: [] };

  activeTab: SearchTabs = tabsName[this.searchType];

  search: string = this.searchTerm;
  actualTag: string = this.tag;
  location: IAddress = new Address();

  @Watch("searchEvents")
  async redirectURLToEvent() {
    if (this.searchEvents.total === 1 && this.isURL(this.searchTerm)) {
      return await this.$router.replace({
        name: RouteName.EVENT,
        params: { uuid: this.searchEvents.elements[0].uuid },
      });
    }
  }

  changeTab(index: number) {
    switch (index) {
      case SearchTabs.EVENTS:
        this.$router.push({
          name: RouteName.SEARCH,
          params: { searchTerm: this.searchTerm, searchType: "events" },
        });
        break;
      case SearchTabs.GROUPS:
        this.$router.push({
          name: RouteName.SEARCH,
          params: { searchTerm: this.searchTerm, searchType: "groups" },
        });
        break;
    }
  }

  @Watch("search")
  changeTabForResult() {
    if (this.searchEvents.total === 0 && this.searchGroups.total > 0) {
      this.activeTab = SearchTabs.GROUPS;
    }
    if (this.searchGroups.total === 0 && this.searchEvents.total > 0) {
      this.activeTab = SearchTabs.EVENTS;
    }
  }

  @Watch("search")
  @Watch("$route")
  async loadSearch() {
    (await this.$apollo.queries.searchEvents.refetch()) &&
      this.$apollo.queries.searchGroups.refetch();
  }

  get groups(): IGroup[] {
    return this.searchGroups.elements.map((group) => Object.assign(new Group(), group));
  }

  isURL(url: string): boolean {
    const a = document.createElement("a");
    a.href = url;
    return (a.host && a.host !== window.location.host) as boolean;
  }

  processSearch() {
    this.$apollo.queries.searchEvents.refetch();
  }

  get geohash() {
    if (this.location && this.location.geom) {
      const [lon, lat] = this.location.geom.split(";");
      return ngeohash.encode(lat, lon, 6);
    }
    return undefined;
  }
}
</script>
<style lang="scss">
@import "~bulma/sass/utilities/_all";
@import "~bulma/sass/components/tabs";
@import "~buefy/src/scss/components/tabs";
@import "~bulma/sass/elements/tag";

.searchTabs .tab-content {
  background: #fff;
  min-height: 10em;
}
</style>
