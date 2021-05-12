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
          <router-link :to="{ name: RouteName.USERS }">{{
            $t("Users")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <div v-if="users">
      <b-table
        :data="users.elements"
        :loading="$apollo.queries.users.loading"
        paginated
        backend-pagination
        backend-filtering
        detailed
        :current-page.sync="page"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :show-detail-icon="true"
        :total="users.total"
        :per-page="USERS_PER_PAGE"
        :has-detailed-visible="(row) => row.actors.length > 0"
        @page-change="onPageChange"
        @filters-change="onFiltersChange"
      >
        <b-table-column field="id" width="40" numeric v-slot="props">
          {{ props.row.id }}
        </b-table-column>
        <b-table-column field="email" :label="$t('Email')" searchable>
          <template #searchable="props">
            <b-input
              v-model="props.filters.email"
              :placeholder="$t('Search…')"
              icon="magnify"
              size="is-small"
            />
          </template>
          <template v-slot:default="props">
            <router-link
              class="user-profile"
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
          :label="$t('Confirmed at')"
          :centered="true"
          v-slot="props"
        >
          <template v-if="props.row.confirmedAt">
            {{ props.row.confirmedAt | formatDateTimeString }}
          </template>
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
          {{ props.row.locale }}
        </b-table-column>

        <template #detail="props">
          <router-link
            class="profile"
            v-for="actor in props.row.actors"
            :key="actor.id"
            :to="{ name: RouteName.ADMIN_PROFILE, params: { id: actor.id } }"
          >
            <article class="media">
              <figure class="media-left">
                <p class="image is-32x32" v-if="actor.avatar">
                  <img :src="actor.avatar.url" />
                </p>
                <b-icon v-else size="is-medium" icon="account-circle" />
              </figure>
              <div class="media-content">
                <div class="content">
                  <strong v-if="actor.name">{{ actor.name }}</strong>
                  <small>@{{ actor.preferredUsername }}</small>
                  <p>{{ actor.summary }}</p>
                </div>
              </div>
            </article>
          </router-link>
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
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const USERS_PER_PAGE = 10;

@Component({
  apollo: {
    users: {
      query: LIST_USERS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          email: this.email,
          page: this.page,
          limit: USERS_PER_PAGE,
        };
      },
    },
  },
})
export default class Users extends Vue {
  USERS_PER_PAGE = USERS_PER_PAGE;

  RouteName = RouteName;

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter({ page: page.toString() });
  }

  get email(): string {
    return (this.$route.query.email as string) || "";
  }

  set email(email: string) {
    this.pushRouter({ email });
  }

  async onPageChange(page: number): Promise<void> {
    this.page = page;
    await this.$apollo.queries.users.fetchMore({
      variables: {
        email: this.email,
        page: this.page,
        limit: USERS_PER_PAGE,
      },
    });
  }

  onFiltersChange({ email }: { email: string }): void {
    this.email = email;
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
