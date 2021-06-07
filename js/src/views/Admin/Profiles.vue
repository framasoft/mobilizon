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
            $t("Profiles")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <div v-if="persons">
      <b-switch v-model="local">{{ $t("Local") }}</b-switch>
      <b-switch v-model="suspended">{{ $t("Suspended") }}</b-switch>
      <b-table
        :data="persons.elements"
        :loading="$apollo.queries.persons.loading"
        paginated
        backend-pagination
        backend-filtering
        :debounce-search="200"
        :current-page.sync="page"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="persons.total"
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
                name: RouteName.ADMIN_PROFILE,
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
          <empty-content icon="account" :inline="true">
            {{ $t("No profile matches the filters") }}
          </empty-content>
        </template>
      </b-table>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { LIST_PROFILES } from "../../graphql/actor";
import RouteName from "../../router/name";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import VueRouter from "vue-router";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const PROFILES_PER_PAGE = 10;

@Component({
  apollo: {
    persons: {
      query: LIST_PROFILES,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          preferredUsername: this.preferredUsername,
          name: this.name,
          domain: this.domain,
          local: this.local,
          suspended: this.suspended,
          page: this.page,
          limit: PROFILES_PER_PAGE,
        };
      },
    },
  },
  components: {
    EmptyContent,
  },
  metaInfo() {
    return {
      title: this.$t("Profiles") as string,
    };
  },
})
export default class Profiles extends Vue {
  PROFILES_PER_PAGE = PROFILES_PER_PAGE;

  RouteName = RouteName;

  async onPageChange(): Promise<void> {
    await this.doFetchMore();
  }

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter({ page: page.toString() });
  }

  get domain(): string {
    return (this.$route.query.domain as string) || "";
  }

  set domain(domain: string) {
    this.pushRouter({ domain });
  }

  get preferredUsername(): string {
    return (this.$route.query.preferredUsername as string) || "";
  }

  set preferredUsername(preferredUsername: string) {
    this.pushRouter({ preferredUsername });
  }

  get local(): boolean {
    return this.$route.query.local === "1";
  }

  set local(local: boolean) {
    this.pushRouter({ local: local ? "1" : "0" });
  }

  get suspended(): boolean {
    return this.$route.query.suspended === "1";
  }

  set suspended(suspended: boolean) {
    this.pushRouter({ suspended: suspended ? "1" : "0" });
  }

  private async pushRouter(args: Record<string, string>): Promise<void> {
    try {
      await this.$router.push({
        name: RouteName.PROFILES,
        query: { ...this.$route.query, ...args },
      });
    } catch (e) {
      if (isNavigationFailure(e, NavigationFailureType.redirected)) {
        throw Error(e.toString());
      }
    }
  }

  private async doFetchMore(): Promise<void> {
    await this.$apollo.queries.persons.fetchMore({
      variables: {
        preferredUsername: this.preferredUsername,
        domain: this.domain,
        local: this.local,
        suspended: this.suspended,
        page: this.page,
        limit: PROFILES_PER_PAGE,
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
    this.doFetchMore();
  }
}
</script>
<style lang="scss" scoped>
a.profile {
  text-decoration: none;
}
</style>
