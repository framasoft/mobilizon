<template>
    <section class="container">
        <h1>
            {{ $t('Search results: "{search}"', { search: this.searchTerm }) }}
        </h1>
        <b-loading :active.sync="$apollo.loading" />
        <b-tabs v-model="activeTab" type="is-boxed" class="searchTabs" @change="changeTab">
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="calendar"></b-icon>
                    <span>
                        {{ $t('Events') }} <b-tag rounded>{{ searchEvents.total }}</b-tag>
                    </span>
                </template>
                <div v-if="searchEvents.total > 0" class="columns is-multiline">
                    <div class="column is-one-quarter-desktop is-half-mobile"
                         v-for="event in searchEvents.elements"
                         :key="event.uuid">
                        <EventCard
                                :event="event"
                        />
                    </div>
                </div>
                <b-message v-else-if="$apollo.loading === false" type="is-danger">
                    {{ $t('No events found') }}
                </b-message>
            </b-tab-item>
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="account-multiple"></b-icon>
                    <span>
                        {{ $t('Groups') }} <b-tag rounded>{{ searchGroups.total }}</b-tag>
                    </span>
                </template>
                <div v-if="searchGroups.total > 0" class="columns is-multiline">
                    <div class="column is-one-quarter-desktop is-half-mobile"
                         v-for="group in groups"
                         :key="group.uuid">
                        <group-card :group="group" />
                    </div>
                </div>
                <b-message v-else-if="$apollo.loading === false" type="is-danger">
                    {{ $t('No groups found') }}
                </b-message>
            </b-tab-item>
        </b-tabs>
    </section>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { SEARCH_EVENTS, SEARCH_GROUPS } from '@/graphql/search';
import { RouteName } from '@/router';
import EventCard from '@/components/Event/EventCard.vue';
import GroupCard from '@/components/Group/GroupCard.vue';
import { Group, IGroup } from '@/types/actor';
import { SearchEvent, SearchGroup } from '@/types/search.model';

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
    searchEvents: {
      query: SEARCH_EVENTS,
      variables() {
        return {
          searchText: this.searchTerm,
        };
      },
      skip() {
        return !this.searchTerm;
      },
    },
    searchGroups: {
      query: SEARCH_GROUPS,
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

  searchEvents: SearchEvent = { total: 0, elements: [] };
  searchGroups: SearchGroup = { total: 0, elements: [] };
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
    if (this.searchEvents.total === 0 && this.searchGroups.total > 0) {
      this.activeTab = SearchTabs.GROUPS;
    }
    if (this.searchGroups.total === 0 && this.searchEvents.total > 0) {
      this.activeTab = SearchTabs.EVENTS;
    }
  }

  @Watch('search')
  @Watch('$route')
  async loadSearch() {
    await this.$apollo.queries['searchEvents'].refetch() && this.$apollo.queries['searchGroups'].refetch();
  }


  get groups(): IGroup[] {
    return this.searchGroups.elements.map(group => Object.assign(new Group(), group));
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
