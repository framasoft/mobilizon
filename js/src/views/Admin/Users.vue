<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MODERATION, text: $t('Moderation') },
        {
          name: RouteName.USERS,
          text: $t('Users'),
        },
      ]"
    />
    <div v-if="users">
      <form @submit.prevent="activateFilters">
        <b-field class="mb-5" grouped group-multiline>
          <b-field :label="$t('Email')" expanded>
            <b-input trap-focus icon="email" v-model="emailFilterFieldValue" />
          </b-field>
          <b-field :label="$t('IP Address')" expanded>
            <b-input icon="web" v-model="ipFilterFieldValue" />
          </b-field>
          <p class="control self-end mb-0">
            <b-button type="is-primary" native-type="submit">{{
              $t("Filter")
            }}</b-button>
          </p>
        </b-field>
      </form>
      <b-table
        :data="users.elements"
        :loading="$apollo.queries.users.loading"
        paginated
        backend-pagination
        :debounce-search="500"
        :current-page.sync="page"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :show-detail-icon="true"
        :total="users.total"
        :per-page="USERS_PER_PAGE"
        @page-change="onPageChange"
      >
        <b-table-column field="id" width="40" numeric v-slot="props">
          {{ props.row.id }}
        </b-table-column>
        <b-table-column field="email" :label="$t('Email')">
          <template v-slot:default="props">
            <router-link
              :to="{
                name: RouteName.ADMIN_USER_PROFILE,
                params: { id: props.row.id },
              }"
              :class="{ disabled: props.row.disabled }"
            >
              {{ props.row.email }}
            </router-link>
          </template>
        </b-table-column>
        <b-table-column
          field="confirmedAt"
          :label="$t('Last seen on')"
          :centered="true"
          v-slot="props"
        >
          <template v-if="props.row.currentSignInAt">
            <time :datetime="props.row.currentSignInAt">
              {{ props.row.currentSignInAt | formatDateTimeString }}
            </time>
          </template>
          <template v-else-if="props.row.confirmedAt"> - </template>
          <template v-else>
            {{ $t("Not confirmed") }}
          </template>
        </b-table-column>
        <b-table-column
          field="locale"
          :label="$t('Language')"
          :centered="true"
          v-slot="props"
        >
          {{ getLanguageNameForCode(props.row.locale) }}
        </b-table-column>
        <template #empty>
          <empty-content
            v-if="!$apollo.loading && emailFilter"
            :inline="true"
            icon="account"
          >
            {{ $t("No user matches the filters") }}
            <template #desc>
              <b-button type="is-primary" @click="resetFilters">
                {{ $t("Reset filters") }}
              </b-button>
            </template>
          </empty-content>
        </template>
      </b-table>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { LIST_USERS } from "../../graphql/user";
import RouteName from "../../router/name";
import VueRouter from "vue-router";
import { LANGUAGES_CODES } from "@/graphql/admin";
import { IUser } from "@/types/current-user.model";
import { Paginate } from "@/types/paginate";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const USERS_PER_PAGE = 10;

@Component({
  apollo: {
    users: {
      query: LIST_USERS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          email: this.emailFilter,
          currentSignInIp: this.ipFilter,
          page: this.page,
          limit: USERS_PER_PAGE,
        };
      },
    },
    languages: {
      query: LANGUAGES_CODES,
      variables() {
        return {
          codes: this.languagesCodes,
        };
      },
      skip() {
        return this.languagesCodes.length < 1;
      },
    },
  },
  metaInfo() {
    return {
      title: this.$t("Users") as string,
    };
  },
  components: {
    EmptyContent,
  },
})
export default class Users extends Vue {
  USERS_PER_PAGE = USERS_PER_PAGE;

  RouteName = RouteName;

  users!: Paginate<IUser>;
  languages!: Array<{ code: string; name: string }>;

  emailFilterFieldValue = this.emailFilter;
  ipFilterFieldValue = this.ipFilter;

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter({ page: page.toString() });
  }

  get emailFilter(): string {
    return (this.$route.query.emailFilter as string) || "";
  }

  set emailFilter(emailFilter: string) {
    this.pushRouter({ emailFilter });
  }

  get ipFilter(): string {
    return (this.$route.query.ipFilter as string) || "";
  }

  set ipFilter(ipFilter: string) {
    this.pushRouter({ ipFilter });
  }

  get languagesCodes(): string[] {
    return (this.users?.elements || []).map((user: IUser) => user.locale);
  }

  getLanguageNameForCode(code: string): string {
    return (
      (this.languages || []).find(({ code: languageCode }) => {
        return languageCode === code;
      })?.name || code
    );
  }

  async onPageChange(page: number): Promise<void> {
    this.page = page;
    await this.$apollo.queries.users.fetchMore({
      variables: {
        email: this.emailFilter,
        currentSignInIp: this.ipFilter,
        page: this.page,
        limit: USERS_PER_PAGE,
      },
    });
  }

  activateFilters(): void {
    this.emailFilter = this.emailFilterFieldValue;
    this.ipFilter = this.ipFilterFieldValue;
  }

  resetFilters(): void {
    this.emailFilterFieldValue = "";
    this.ipFilterFieldValue = "";
    this.activateFilters();
  }

  private async pushRouter(args: Record<string, string>): Promise<void> {
    try {
      await this.$router.push({
        name: RouteName.USERS,
        query: { ...this.$route.query, ...args },
      });
    } catch (e) {
      if (isNavigationFailure(e, NavigationFailureType.redirected)) {
        throw Error(e.toString());
      }
    }
  }
}
</script>

<style lang="scss" scoped>
a.profile,
a.user-profile {
  text-decoration: none;
}
a.disabled {
  color: $danger;
  text-decoration: line-through;
}
</style>
