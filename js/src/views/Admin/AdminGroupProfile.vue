<template>
  <div v-if="group" class="section">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{
            $t("Admin")
          }}</router-link>
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.ADMIN_GROUPS,
            }"
            >{{ $t("Groups") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.PROFILES,
              params: { id: group.id },
            }"
            >{{ group.name || group.preferredUsername }}</router-link
          >
        </li>
      </ul>
    </nav>
    <div class="actor-card">
      <router-link
        :to="{
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
        }"
      >
        <actor-card
          :actor="group"
          :full="true"
          :popover="false"
          :limit="false"
        />
      </router-link>
    </div>
    <table v-if="metadata.length > 0" class="table is-fullwidth">
      <tbody>
        <tr v-for="{ key, value, link } in metadata" :key="key">
          <td>{{ key }}</td>
          <td v-if="link">
            <router-link :to="link">
              {{ value }}
            </router-link>
          </td>
          <td v-else>{{ value }}</td>
        </tr>
      </tbody>
    </table>
    <div class="buttons">
      <b-button
        @click="confirmSuspendProfile"
        v-if="!group.suspended"
        type="is-primary"
        >{{ $t("Suspend") }}</b-button
      >
      <b-button
        @click="unsuspendProfile"
        v-if="group.suspended"
        type="is-primary"
        >{{ $t("Unsuspend") }}</b-button
      >
      <b-button
        @click="refreshProfile"
        v-if="group.domain"
        type="is-primary"
        outlined
        >{{ $t("Refresh profile") }}</b-button
      >
    </div>
    <section>
      <h2 class="subtitle">
        {{
          $tc("{number} members", group.members.total, {
            number: group.members.total,
          })
        }}
      </h2>
      <b-table
        :data="group.members.elements"
        :loading="$apollo.queries.group.loading"
        paginated
        backend-pagination
        :total="group.members.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onMembersPageChange"
      >
        <b-table-column
          field="actor.preferredUsername"
          :label="$t('Member')"
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
        <b-table-column field="role" :label="$t('Role')" v-slot="props">
          <b-tag
            type="is-primary"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ $t("Administrator") }}
          </b-tag>
          <b-tag
            type="is-primary"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ $t("Moderator") }}
          </b-tag>
          <b-tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ $t("Member") }}
          </b-tag>
          <b-tag
            type="is-warning"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ $t("Not approved") }}
          </b-tag>
          <b-tag
            type="is-danger"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ $t("Rejected") }}
          </b-tag>
          <b-tag
            type="is-danger"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ $t("Invited") }}
          </b-tag>
        </b-table-column>
        <b-table-column field="insertedAt" :label="$t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ props.row.insertedAt | formatDateString }}<br />{{
              props.row.insertedAt | formatTimeString
            }}
          </span>
        </b-table-column>
        <template slot="empty">
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("Nothing to see here") }}</p>
            </div>
          </section>
        </template>
      </b-table>
    </section>
    <section>
      <h2 class="subtitle">
        {{
          $tc("{number} organized events", group.organizedEvents.total, {
            number: group.organizedEvents.total,
          })
        }}
      </h2>
      <b-table
        :data="group.organizedEvents.elements"
        :loading="$apollo.queries.group.loading"
        paginated
        backend-pagination
        :total="group.organizedEvents.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onOrganizedEventsPageChange"
      >
        <b-table-column field="title" :label="$t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
            <b-tag type="is-info" v-if="props.row.draft">{{
              $t("Draft")
            }}</b-tag>
          </router-link>
        </b-table-column>
        <b-table-column
          field="beginsOn"
          :label="$t('Begins on')"
          v-slot="props"
        >
          {{ props.row.beginsOn | formatDateTimeString }}
        </b-table-column>
        <template slot="empty">
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("Nothing to see here") }}</p>
            </div>
          </section>
        </template>
      </b-table>
    </section>
    <section>
      <h2 class="subtitle">
        {{
          $tc("{number} posts", group.posts.total, {
            number: group.posts.total,
          })
        }}
      </h2>
      <b-table
        :data="group.posts.elements"
        :loading="$apollo.queries.group.loading"
        paginated
        backend-pagination
        :total="group.posts.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onPostsPageChange"
      >
        <b-table-column field="title" :label="$t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.POST, params: { slug: props.row.slug } }"
          >
            {{ props.row.title }}
            <b-tag type="is-info" v-if="props.row.draft">{{
              $t("Draft")
            }}</b-tag>
          </router-link>
        </b-table-column>
        <b-table-column
          field="publishAt"
          :label="$t('Publication date')"
          v-slot="props"
        >
          {{ props.row.publishAt | formatDateTimeString }}
        </b-table-column>
        <template slot="empty">
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("Nothing to see here") }}</p>
            </div>
          </section>
        </template>
      </b-table>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { GET_GROUP, REFRESH_PROFILE } from "@/graphql/group";
import { formatBytes } from "@/utils/datetime";
import { MemberRole } from "@/types/enums";
import { SUSPEND_PROFILE, UNSUSPEND_PROFILE } from "../../graphql/actor";
import { IGroup } from "../../types/actor";
import { usernameWithDomain, IActor } from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import ActorCard from "../../components/Account/ActorCard.vue";

const EVENTS_PER_PAGE = 10;

@Component({
  apollo: {
    group: {
      query: GET_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.id,
          organizedEventsPage: 1,
          organizedEventsLimit: EVENTS_PER_PAGE,
        };
      },
      skip() {
        return !this.id;
      },
      update: (data) => data.getGroup,
    },
  },
  components: {
    ActorCard,
  },
})
export default class AdminGroupProfile extends Vue {
  @Prop({ required: true }) id!: string;

  group!: IGroup;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  EVENTS_PER_PAGE = EVENTS_PER_PAGE;

  organizedEventsPage = 1;

  membersPage = 1;

  postsPage = 1;

  MemberRole = MemberRole;

  get metadata(): Array<Record<string, string>> {
    if (!this.group) return [];
    const res: Record<string, string>[] = [
      {
        key: this.$t("Status") as string,
        value: (this.group.suspended
          ? this.$t("Suspended")
          : this.$t("Active")) as string,
      },
      {
        key: this.$t("Domain") as string,
        value: (this.group.domain
          ? this.group.domain
          : this.$t("Local")) as string,
      },
      {
        key: this.$i18n.t("Uploaded media size") as string,
        value: formatBytes(this.group.mediaSize),
      },
    ];
    return res;
  }

  confirmSuspendProfile(): void {
    const message = (this.group.domain
      ? this.$t(
          "Are you sure you want to <b>suspend</b> this group? As this group originates from instance {instance}, this will only remove local members and delete the local data, as well as rejecting all the future data.",
          { instance: this.group.domain }
        )
      : this.$t(
          "Are you sure you want to <b>suspend</b> this group? All members - including remote ones - will be notified and removed from the group, and <b>all of the group data (events, posts, discussions, todos…) will be irretrievably destroyed</b>."
        )) as string;

    this.$buefy.dialog.confirm({
      title: this.$t("Suspend group") as string,
      message,
      confirmText: this.$t("Suspend group") as string,
      cancelText: this.$t("Cancel") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => this.suspendProfile(),
    });
  }

  async suspendProfile(): Promise<void> {
    this.$apollo.mutate<{ suspendProfile: { id: string } }>({
      mutation: SUSPEND_PROFILE,
      variables: {
        id: this.id,
      },
      update: (store, { data }) => {
        if (data == null) return;
        const profileId = this.id;

        const profileData = store.readQuery<{ getGroup: IGroup }>({
          query: GET_GROUP,
          variables: {
            id: profileId,
          },
        });

        if (!profileData) return;
        const { getGroup: group } = profileData;
        group.suspended = true;
        group.avatar = null;
        group.name = "";
        group.summary = "";
        store.writeQuery({
          query: GET_GROUP,
          variables: {
            id: profileId,
          },
          data: { getGroup: group },
        });
      },
    });
  }

  async unsuspendProfile(): Promise<void> {
    const profileID = this.id;
    await this.$apollo.mutate<{ unsuspendProfile: { id: string } }>({
      mutation: UNSUSPEND_PROFILE,
      variables: {
        id: this.id,
      },
      refetchQueries: [
        {
          query: GET_GROUP,
          variables: {
            id: profileID,
          },
        },
      ],
    });
  }

  async refreshProfile(): Promise<void> {
    this.$apollo.mutate<{ refreshProfile: IActor }>({
      mutation: REFRESH_PROFILE,
      variables: {
        actorId: this.id,
      },
    });
  }

  async onOrganizedEventsPageChange(page: number): Promise<void> {
    this.organizedEventsPage = page;
    await this.$apollo.queries.group.fetchMore({
      variables: {
        actorId: this.id,
        organizedEventsPage: this.organizedEventsPage,
        organizedEventsLimit: EVENTS_PER_PAGE,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newOrganizedEvents =
          fetchMoreResult.group.organizedEvents.elements;
        return {
          group: {
            ...previousResult.group,
            organizedEvents: {
              __typename: previousResult.group.organizedEvents.__typename,
              total: previousResult.group.organizedEvents.total,
              elements: [
                ...previousResult.group.organizedEvents.elements,
                ...newOrganizedEvents,
              ],
            },
          },
        };
      },
    });
  }

  async onMembersPageChange(page: number): Promise<void> {
    this.membersPage = page;
    await this.$apollo.queries.group.fetchMore({
      variables: {
        actorId: this.id,
        memberPage: this.membersPage,
        memberLimit: EVENTS_PER_PAGE,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newMembers = fetchMoreResult.group.members.elements;
        return {
          group: {
            ...previousResult.group,
            members: {
              __typename: previousResult.group.members.__typename,
              total: previousResult.group.members.total,
              elements: [
                ...previousResult.group.members.elements,
                ...newMembers,
              ],
            },
          },
        };
      },
    });
  }

  async onPostsPageChange(page: number): Promise<void> {
    this.postsPage = page;
    await this.$apollo.queries.group.fetchMore({
      variables: {
        actorId: this.id,
        postsPage: this.postsPage,
        postLimit: EVENTS_PER_PAGE,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newPosts = fetchMoreResult.group.posts.elements;
        return {
          group: {
            ...previousResult.group,
            posts: {
              __typename: previousResult.group.posts.__typename,
              total: previousResult.group.posts.total,
              elements: [...previousResult.group.posts.elements, ...newPosts],
            },
          },
        };
      },
    });
  }
}
</script>

<style lang="scss" scoped>
table,
section {
  margin: 2rem 0;
}

.actor-card {
  background: #fff;
  padding: 1.5rem;
  border-radius: 10px;
}
</style>
