<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MODERATION }">{{
            $t("Moderation")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.PROFILES }">{{
            $t("Groups")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <div v-if="groups">
      <b-switch v-model="local">{{ $t("Local") }}</b-switch>
      <b-switch v-model="suspended">{{ $t("Suspended") }}</b-switch>
      <b-table
        :data="groups.elements"
        :loading="$apollo.queries.groups.loading"
        paginated
        backend-pagination
        backend-filtering
        :total="groups.total"
        :per-page="PROFILES_PER_PAGE"
        @page-change="onPageChange"
        @filters-change="onFiltersChange"
      >
        <b-table-column
          field="preferredUsername"
          :label="$t('Username')"
          searchable
        >
          <template #searchable="props">
            <b-input
              v-model="props.filters.preferredUsername"
              placeholder="Search..."
              icon="magnify"
              size="is-small"
            />
          </template>
          <template v-slot:default="props">
            <router-link
              class="profile"
              :to="{
                name: RouteName.ADMIN_GROUP_PROFILE,
                params: { id: props.row.id },
              }"
            >
              <article class="media">
                <figure class="media-left" v-if="props.row.avatar">
                  <p class="image is-48x48">
                    <img :src="props.row.avatar.url" />
                  </p>
                </figure>
                <div class="media-content">
                  <div class="content">
                    <strong v-if="props.row.name">{{ props.row.name }}</strong
                    ><br v-if="props.row.name" />
                    <small>@{{ props.row.preferredUsername }}</small>
                  </div>
                </div>
              </article>
            </router-link>
          </template>
        </b-table-column>

        <b-table-column field="domain" :label="$t('Domain')" searchable>
          <template #searchable="props">
            <b-input
              v-model="props.filters.domain"
              placeholder="Search..."
              icon="magnify"
              size="is-small"
            />
          </template>
          <template v-slot:default="props">
            {{ props.row.domain }}
          </template>
        </b-table-column>
        <template slot="empty">
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("No profile matches the filters") }}</p>
            </div>
          </section>
        </template>
      </b-table>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { LIST_GROUPS } from "@/graphql/group";
import RouteName from "../../router/name";

const PROFILES_PER_PAGE = 10;

@Component({
  apollo: {
    groups: {
      query: LIST_GROUPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          preferredUsername: this.preferredUsername,
          name: this.name,
          domain: this.domain,
          local: this.local,
          suspended: this.suspended,
          page: 1,
          limit: PROFILES_PER_PAGE,
        };
      },
    },
  },
})
export default class GroupProfiles extends Vue {
  page = 1;

  preferredUsername = "";

  name = "";

  domain = "";

  local = true;

  suspended = false;

  PROFILES_PER_PAGE = PROFILES_PER_PAGE;

  RouteName = RouteName;

  async onPageChange(page: number): Promise<void> {
    this.page = page;
    await this.$apollo.queries.groups.fetchMore({
      variables: {
        preferredUsername: this.preferredUsername,
        name: this.name,
        domain: this.domain,
        local: this.local,
        suspended: this.suspended,
        page: this.page,
        limit: PROFILES_PER_PAGE,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newProfiles = fetchMoreResult.groups.elements;
        return {
          groups: {
            __typename: previousResult.groups.__typename,
            total: previousResult.groups.total,
            elements: [...previousResult.groups.elements, ...newProfiles],
          },
        };
      },
    });
  }

  onFiltersChange({
    preferredUsername,
    domain,
  }: {
    preferredUsername: string;
    domain: string;
  }): void {
    this.preferredUsername = preferredUsername;
    this.domain = domain;
  }

  @Watch("domain")
  domainNotLocal(): void {
    this.local = this.domain === "";
  }
}
</script>
<style lang="scss" scoped>
a.profile {
  text-decoration: none;
}
</style>
