<template>
    <section class="container">
        <h1>
            <translate :translate-params="{ search: this.searchTerm }">Search results: « %{ search } »</translate>
        </h1>
        <b-loading :active.sync="$apollo.loading" />
        <b-tabs v-model="activeTab" type="is-boxed" class="searchTabs" @change="changeTab">
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="calendar"></b-icon>
                    <span><translate>Events</translate> <b-tag rounded>{{ events.length }}</b-tag> </span>
                </template>
                <div v-if="search.length > 0" class="columns is-multiline">
                    <div class="column is-one-quarter-desktop is-half-mobile"
                         v-for="event in events"
                         :key="event.uuid">
                        <EventCard
                                :event="event"
                        />
                    </div>
                </div>
                <b-message v-else-if="$apollo.loading === false" type="is-danger">
                    <translate>No events found</translate>
                </b-message>
            </b-tab-item>
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="account-multiple"></b-icon>
                    <span><translate>Groups</translate> <b-tag rounded>{{ groups.length }}</b-tag> </span>
                </template>
                <div v-if="groups.length > 0" class="columns is-multiline">
                    <div class="column is-one-quarter-desktop is-half-mobile"
                         v-for="group in groups"
                         :key="group.uuid">
                        <group-card :group="group" />
                    </div>
                </div>
                <b-message v-else-if="$apollo.loading === false" type="is-danger">
                    <translate>No groups found</translate>
                </b-message>
            </b-tab-item>
        </b-tabs>
    </section>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { SEARCH } from '@/graphql/search';
import { RouteName } from '@/router';
import { IEvent } from '@/types/event.model';
import { ISearch } from '@/types/search.model';
import EventCard from '@/components/Event/EventCard.vue';
import { IGroup, Group } from '@/types/actor.model';
import GroupCard from '@/components/Group/GroupCard.vue';

enum SearchTabs {
    EVENTS = 0,
    GROUPS = 1,
    PERSONS = 2, // not used right now
}

const tabsName = {
  events: SearchTabs.EVENTS,
  groups: SearchTabs.GROUPS,
};

@Component({
  apollo: {
    search: {
      query: SEARCH,
      variables() {
        return {
          searchText: this.searchTerm,
        };
      },
      skip() {
        return !this.searchTerm;
      },
    },
  },
  components: {
    GroupCard,
    EventCard,
  },
})
export default class Search extends Vue {
  @Prop({ type: String, required: true }) searchTerm!: string;
  @Prop({ type: String, required: false, default: 'events' }) searchType!: string;

  search = [];
  activeTab: SearchTabs = tabsName[this.searchType];

  changeTab(index: number) {
    switch (index) {
      case SearchTabs.EVENTS:
        this.$router.push({ name: RouteName.SEARCH, params: { searchTerm: this.searchTerm, searchType: 'events' } });
        break;
      case SearchTabs.GROUPS:
        this.$router.push({ name: RouteName.SEARCH, params: { searchTerm: this.searchTerm, searchType: 'groups' } });
        break;
    }
  }

  @Watch('search')
  changeTabForResult() {
    if (this.events.length === 0 && this.groups.length > 0) {
      this.activeTab = SearchTabs.GROUPS;
    }
    if (this.groups.length === 0 && this.events.length > 0) {
      this.activeTab = SearchTabs.EVENTS;
    }
  }

  @Watch('search')
  @Watch('$route')
  async loadSearch() {
    await this.$apollo.queries['search'].refetch();
  }

  get events(): IEvent[] {
    return this.search.filter((value: ISearch) => { return value.__typename === 'Event'; }) as IEvent[];
  }

  get groups(): IGroup[] {
    const groups = this.search.filter((value: ISearch) => { return value.__typename === 'Group'; }) as IGroup[];
    return groups.map(group => Object.assign(new Group(), group));
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
