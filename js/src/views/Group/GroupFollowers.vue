<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul v-if="group">
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP_SETTINGS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Settings") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.GROUP_FOLLOWERS_SETTINGS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Followers") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section
      class="container section"
      v-if="group && isCurrentActorAGroupAdmin && followers"
    >
      <h1>{{ $t("Group Followers") }} ({{ followers.total }})</h1>
      <b-field :label="$t('Status')" horizontal>
        <b-switch v-model="pending">{{ $t("Pending") }}</b-switch>
      </b-field>
      <b-table
        :data="followers.elements"
        ref="queueTable"
        :loading="this.$apollo.loading"
        paginated
        backend-pagination
        :current-page.sync="page"
        :pagination-simple="true"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="followers.total"
        :per-page="FOLLOWERS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="triggerLoadMoreFollowersPageChange"
        @sort="(field, order) => $emit('sort', field, order)"
      >
        <b-table-column
          field="actor.preferredUsername"
          :label="$t('Follower')"
          v-slot="props"
        >
          <article class="media">
            <figure
              class="media-left image is-48x48"
              v-if="props.row.actor.avatar"
            >
              <img
                class="is-rounded"
                :src="props.row.actor.avatar.url"
                alt=""
              />
            </figure>
            <b-icon
              class="media-left"
              v-else
              size="is-large"
              icon="account-circle"
            />
            <div class="media-content">
              <div class="content">
                <span v-if="props.row.actor.name">{{
                  props.row.actor.name
                }}</span
                ><br />
                <span class="is-size-7 has-text-grey"
                  >@{{ usernameWithDomain(props.row.actor) }}</span
                >
              </div>
            </div>
          </article>
        </b-table-column>
        <b-table-column field="insertedAt" :label="$t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ props.row.insertedAt | formatDateString }}<br />{{
              props.row.insertedAt | formatTimeString
            }}
          </span>
        </b-table-column>
        <b-table-column field="actions" :label="$t('Actions')" v-slot="props">
          <div class="buttons">
            <b-button
              v-if="!props.row.approved"
              @click="updateFollower(props.row, true)"
              icon-left="check"
              type="is-success"
              >{{ $t("Accept") }}</b-button
            >
            <b-button
              @click="updateFollower(props.row, false)"
              icon-left="close"
              type="is-danger"
              >{{ $t("Reject") }}</b-button
            >
          </div>
        </b-table-column>
        <template slot="empty">
          <empty-content icon="account" inline>
            {{ $t("No follower matches the filters") }}
          </empty-content>
        </template>
      </b-table>
    </section>
    <b-message v-else-if="group">
      {{ $t("You are not an administrator for this group.") }}
    </b-message>
  </div>
</template>

<script lang="ts">
import { Component, Watch } from "vue-property-decorator";
import GroupMixin from "@/mixins/group";
import { mixins } from "vue-class-component";
import { GROUP_FOLLOWERS, UPDATE_FOLLOWER } from "@/graphql/followers";
import RouteName from "../../router/name";
import { usernameWithDomain } from "../../types/actor";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { IFollower } from "@/types/actor/follower.model";
import { Paginate } from "@/types/paginate";

@Component({
  apollo: {
    followers: {
      query: GROUP_FOLLOWERS,
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          followersPage: this.page,
          followersLimit: this.FOLLOWERS_PER_PAGE,
          approved: this.pending === null ? null : !this.pending,
        };
      },
      update: (data) => data.group.followers,
    },
  },
  components: {
    EmptyContent,
  },
})
export default class GroupFollowers extends mixins(GroupMixin) {
  loading = true;

  RouteName = RouteName;

  page = parseInt((this.$route.query.page as string) || "1", 10);

  pending: boolean | null =
    (this.$route.query.pending as string) == "1" || null;

  FOLLOWERS_PER_PAGE = 10;

  usernameWithDomain = usernameWithDomain;

  followers!: Paginate<IFollower>;

  mounted(): void {
    this.page = parseInt((this.$route.query.page as string) || "1", 10);
  }

  @Watch("page")
  triggerLoadMoreFollowersPageChange(page: string): void {
    this.$router.replace({
      name: RouteName.GROUP_FOLLOWERS_SETTINGS,
      query: { ...this.$route.query, page },
    });
  }

  @Watch("pending")
  triggerPendingStatusPageChange(pending: boolean): void {
    this.$router.replace({
      name: RouteName.GROUP_FOLLOWERS_SETTINGS,
      query: { ...this.$route.query, ...{ pending: pending ? "1" : "0" } },
    });
  }

  async loadMoreFollowers(): Promise<void> {
    const { FOLLOWERS_PER_PAGE, group, page, pending } = this;
    await this.$apollo.queries.followers.fetchMore({
      // New variables
      variables() {
        return {
          name: usernameWithDomain(group),
          followersPage: page,
          followersLimit: FOLLOWERS_PER_PAGE,
          approved: !pending,
        };
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const oldFollowers = previousResult.group.followers;
        const newFollowers = fetchMoreResult.group.followers;
        return {
          elements: [...oldFollowers.elements, ...newFollowers.elements],
          total: newFollowers.total,
          __typename: oldFollowers.__typename,
        };
      },
    });
  }

  async updateFollower(follower: IFollower, approved: boolean): Promise<void> {
    const { FOLLOWERS_PER_PAGE, group, page, pending } = this;
    try {
      await this.$apollo.mutate<{ rejectFollower: IFollower }>({
        mutation: UPDATE_FOLLOWER,
        variables: {
          id: follower.id,
          approved,
        },
        refetchQueries: [
          {
            query: GROUP_FOLLOWERS,
            variables: {
              name: usernameWithDomain(group),
              followersPage: page,
              followersLimit: FOLLOWERS_PER_PAGE,
              approved: !pending,
            },
          },
        ],
      });
      const message = approved
        ? this.$t("@{username}'s follow request was accepted", {
            username: follower.actor.preferredUsername,
          })
        : this.$t("@{username}'s follow request was rejected", {
            username: follower.actor.preferredUsername,
          });
      this.$notifier.success(message as string);
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }
}
</script>
