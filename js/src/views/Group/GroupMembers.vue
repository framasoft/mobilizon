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
              name: RouteName.GROUP_MEMBERS_SETTINGS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Members") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section class="container section" v-if="group">
      <form @submit.prevent="inviteMember">
        <b-field :label="$t('Invite a new member')" custom-class="add-relay" horizontal>
          <b-field grouped expanded size="is-large">
            <p class="control">
              <b-input v-model="newMemberUsername" :placeholder="$t('Ex: someone@mobilizon.org')" />
            </p>
            <p class="control">
              <b-button type="is-primary" native-type="submit">{{ $t("Invite member") }}</b-button>
            </p>
          </b-field>
        </b-field>
      </form>
      <h1>{{ $t("Group Members") }} ({{ group.members.total }})</h1>
      <b-field :label="$t('Status')" horizontal>
        <b-select v-model="roles">
          <option value="">
            {{ $t("Everything") }}
          </option>
          <option :value="MemberRole.ADMINISTRATOR">
            {{ $t("Administrator") }}
          </option>
          <option :value="MemberRole.MODERATOR">
            {{ $t("Moderator") }}
          </option>
          <option :value="MemberRole.MEMBER">
            {{ $t("Member") }}
          </option>
          <option :value="MemberRole.INVITED">
            {{ $t("Invited") }}
          </option>
          <option :value="MemberRole.NOT_APPROVED">
            {{ $t("Not approved") }}
          </option>
          <option :value="MemberRole.REJECTED">
            {{ $t("Rejected") }}
          </option>
        </b-select>
      </b-field>
      <b-table
        :data="group.members.elements"
        ref="queueTable"
        :loading="this.$apollo.loading"
        paginated
        backend-pagination
        :pagination-simple="true"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="group.members.total"
        :per-page="MEMBERS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="(newPage) => (page = newPage)"
        @sort="(field, order) => $emit('sort', field, order)"
      >
        <b-table-column field="actor.preferredUsername" :label="$t('Member')" v-slot="props">
          <article class="media">
            <figure class="media-left image is-48x48" v-if="props.row.actor.avatar">
              <img class="is-rounded" :src="props.row.actor.avatar.url" alt="" />
            </figure>
            <b-icon class="media-left" v-else size="is-large" icon="account-circle" />
            <div class="media-content">
              <div class="content">
                <span v-if="props.row.actor.name">{{ props.row.actor.name }}</span
                ><br />
                <span class="is-size-7 has-text-grey"
                  >@{{ usernameWithDomain(props.row.actor) }}</span
                >
              </div>
            </div>
          </article>
        </b-table-column>
        <b-table-column field="role" :label="$t('Role')" v-slot="props">
          <b-tag type="is-primary" v-if="props.row.role === MemberRole.ADMINISTRATOR">
            {{ $t("Administrator") }}
          </b-tag>
          <b-tag type="is-primary" v-else-if="props.row.role === MemberRole.MODERATOR">
            {{ $t("Moderator") }}
          </b-tag>
          <b-tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ $t("Member") }}
          </b-tag>
          <b-tag type="is-warning" v-else-if="props.row.role === MemberRole.NOT_APPROVED">
            {{ $t("Not approved") }}
          </b-tag>
          <b-tag type="is-danger" v-else-if="props.row.role === MemberRole.REJECTED">
            {{ $t("Rejected") }}
          </b-tag>
          <b-tag type="is-danger" v-else-if="props.row.role === MemberRole.INVITED">
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
        <b-table-column field="actions" :label="$t('Actions')" v-slot="props">
          <div class="buttons">
            <b-button
              v-if="props.row.role === MemberRole.MEMBER"
              @click="promoteMember(props.row.id)"
              >{{ $t("Promote") }}</b-button
            >
            <b-button
              v-if="props.row.role === MemberRole.ADMINISTRATOR"
              @click="demoteMember(props.row.id)"
              >{{ $t("Demote") }}</b-button
            >
            <b-button
              v-if="props.row.role === MemberRole.MEMBER"
              @click="removeMember(props.row.id)"
              type="is-danger"
              >{{ $t("Remove") }}</b-button
            >
          </div>
        </b-table-column>
        <template slot="empty">
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("No member matches the filters") }}</p>
            </div>
          </section>
        </template>
      </b-table>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import RouteName from "../../router/name";
import { INVITE_MEMBER, GROUP_MEMBERS, REMOVE_MEMBER, UPDATE_MEMBER } from "../../graphql/member";
import { IGroup, usernameWithDomain } from "../../types/actor";
import { IMember, MemberRole } from "../../types/actor/group.model";

@Component({
  apollo: {
    group: {
      query: GROUP_MEMBERS,
      // fetchPolicy: "network-only",
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          page: 1,
          limit: this.MEMBERS_PER_PAGE,
          roles: this.roles,
        };
      },
      skip() {
        return !this.$route.params.preferredUsername;
      },
    },
  },
})
export default class GroupMembers extends Vue {
  group!: IGroup;

  loading = true;

  RouteName = RouteName;

  newMemberUsername = "";

  MemberRole = MemberRole;

  roles: MemberRole | "" = "";

  page = 1;

  MEMBERS_PER_PAGE = 10;

  usernameWithDomain = usernameWithDomain;

  mounted() {
    const roleQuery = this.$route.query.role as string;
    if (Object.values(MemberRole).includes(roleQuery as MemberRole)) {
      this.roles = roleQuery as MemberRole;
    }
  }

  async inviteMember() {
    await this.$apollo.mutate<{ inviteMember: IMember }>({
      mutation: INVITE_MEMBER,
      variables: {
        groupId: this.group.id,
        targetActorUsername: this.newMemberUsername,
      },
      update: (store, { data }) => {
        if (data == null) return;
        const query = {
          query: GROUP_MEMBERS,
          variables: {
            name: this.$route.params.preferredUsername,
            page: 1,
            limit: this.MEMBERS_PER_PAGE,
            roles: this.roles,
          },
        };
        const memberData: IMember = data.inviteMember;
        const groupData = store.readQuery<{ group: IGroup }>(query);
        if (!groupData) return;
        const { group } = groupData;
        const index = group.members.elements.findIndex((m) => m.actor.id === memberData.actor.id);
        if (index === -1) {
          group.members.elements.push(memberData);
          group.members.total += 1;
        } else {
          group.members.elements.splice(index, 1, memberData);
        }
        store.writeQuery({ ...query, data: { group } });
      },
    });
    this.newMemberUsername = "";
  }

  @Watch("page")
  loadMoreMembers() {
    this.$apollo.queries.event.fetchMore({
      // New variables
      variables: {
        page: this.page,
        limit: this.MEMBERS_PER_PAGE,
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const oldMembers = previousResult.group.members;
        const newMembers = fetchMoreResult.group.members;

        return {
          group: {
            ...previousResult.event,
            members: {
              elements: [...oldMembers.elements, ...newMembers.elements],
              total: newMembers.total,
              __typename: oldMembers.__typename,
            },
          },
        };
      },
    });
  }

  async removeMember(memberId: string) {
    await this.$apollo.mutate<{ removeMember: IMember }>({
      mutation: REMOVE_MEMBER,
      variables: {
        groupId: this.group.id,
        memberId,
      },
      update: (store, { data }) => {
        if (data == null) return;
        const query = {
          query: GROUP_MEMBERS,
          variables: {
            name: this.$route.params.preferredUsername,
            page: 1,
            limit: this.MEMBERS_PER_PAGE,
            roles: this.roles,
          },
        };
        const groupData = store.readQuery<{ group: IGroup }>(query);
        if (!groupData) return;
        const { group } = groupData;
        const index = group.members.elements.findIndex((m) => m.id === memberId);
        if (index !== -1) {
          group.members.elements.splice(index, 1);
          group.members.total -= 1;
          store.writeQuery({ ...query, data: { group } });
        }
      },
    });
  }

  promoteMember(memberId: string) {
    return this.updateMember(memberId, MemberRole.ADMINISTRATOR);
  }

  demoteMember(memberId: string) {
    return this.updateMember(memberId, MemberRole.MEMBER);
  }

  async updateMember(memberId: string, role: MemberRole) {
    await this.$apollo.mutate<{ updateMember: IMember }>({
      mutation: UPDATE_MEMBER,
      variables: {
        memberId,
        role,
      },
    });
  }
}
</script>
