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
    <section
      class="container section"
      v-if="group && isCurrentActorAGroupAdmin"
    >
      <form @submit.prevent="inviteMember">
        <b-field
          :label="$t('Invite a new member')"
          custom-class="add-relay"
          horizontal
        >
          <b-field
            grouped
            expanded
            size="is-large"
            :type="inviteError ? 'is-danger' : null"
            :message="inviteError"
          >
            <p class="control">
              <b-input
                v-model="newMemberUsername"
                :placeholder="$t('Ex: someone@mobilizon.org')"
              />
            </p>
            <p class="control">
              <b-button type="is-primary" native-type="submit">{{
                $t("Invite member")
              }}</b-button>
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
        v-if="members"
        :data="members.elements"
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
        :total="members.total"
        :per-page="MEMBERS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="triggerLoadMoreMemberPageChange"
        @sort="(field, order) => $emit('sort', field, order)"
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
            type="is-warning"
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
        <b-table-column field="actions" :label="$t('Actions')" v-slot="props">
          <div class="buttons" v-if="props.row.actor.id !== currentActor.id">
            <b-button
              v-if="
                [MemberRole.MEMBER, MemberRole.MODERATOR].includes(
                  props.row.role
                )
              "
              @click="promoteMember(props.row)"
              icon-left="chevron-double-up"
              >{{ $t("Promote") }}</b-button
            >
            <b-button
              v-if="
                [MemberRole.ADMINISTRATOR, MemberRole.MODERATOR].includes(
                  props.row.role
                )
              "
              @click="demoteMember(props.row)"
              icon-left="chevron-double-down"
              >{{ $t("Demote") }}</b-button
            >
            <b-button
              v-if="props.row.role === MemberRole.MEMBER"
              @click="removeMember(props.row.id)"
              type="is-danger"
              icon-left="exit-to-app"
              >{{ $t("Remove") }}</b-button
            >
          </div>
        </b-table-column>
        <template slot="empty">
          <empty-content icon="account" inline>
            {{ $t("No member matches the filters") }}
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
import { FETCH_GROUP } from "@/graphql/group";
import { MemberRole } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";
import {
  INVITE_MEMBER,
  GROUP_MEMBERS,
  REMOVE_MEMBER,
  UPDATE_MEMBER,
} from "../../graphql/member";
import { usernameWithDomain } from "../../types/actor";
import EmptyContent from "@/components/Utils/EmptyContent.vue";

@Component({
  apollo: {
    members: {
      query: GROUP_MEMBERS,
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          page: this.page,
          limit: this.MEMBERS_PER_PAGE,
          roles: this.roles,
        };
      },
      update: (data) => data.group.members,
    },
  },
  components: {
    EmptyContent,
  },
})
export default class GroupMembers extends mixins(GroupMixin) {
  loading = true;

  newMemberUsername = "";

  inviteError = "";

  MemberRole = MemberRole;

  roles: MemberRole | "" = "";

  RouteName = RouteName;

  page = parseInt((this.$route.query.page as string) || "1", 10);

  MEMBERS_PER_PAGE = 10;

  usernameWithDomain = usernameWithDomain;

  mounted(): void {
    const roleQuery = this.$route.query.role as string;
    if (Object.values(MemberRole).includes(roleQuery as MemberRole)) {
      this.roles = roleQuery as MemberRole;
    }
    this.page = parseInt((this.$route.query.page as string) || "1", 10);
  }

  async inviteMember(): Promise<void> {
    try {
      this.inviteError = "";
      const { roles, MEMBERS_PER_PAGE, group, page } = this;
      const variables = {
        name: usernameWithDomain(group),
        page,
        limit: MEMBERS_PER_PAGE,
        roles,
      };
      console.log("variables", variables);
      await this.$apollo.mutate<{ inviteMember: IMember }>({
        mutation: INVITE_MEMBER,
        variables: {
          groupId: this.group.id,
          targetActorUsername: this.newMemberUsername,
        },
        refetchQueries: [
          {
            query: GROUP_MEMBERS,
            variables,
          },
        ],
      });
      this.$notifier.success(
        this.$t("{username} was invited to {group}", {
          username: this.newMemberUsername,
          group: this.group.name || usernameWithDomain(this.group),
        }) as string
      );
      this.newMemberUsername = "";
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.inviteError = error.graphQLErrors[0].message;
      }
    }
  }

  @Watch("page")
  triggerLoadMoreMemberPageChange(page: string): void {
    this.$router.replace({
      name: RouteName.GROUP_MEMBERS_SETTINGS,
      query: { ...this.$route.query, page },
    });
  }

  @Watch("roles")
  triggerLoadMoreMemberRoleChange(roles: string): void {
    this.$router.replace({
      name: RouteName.GROUP_MEMBERS_SETTINGS,
      query: { ...this.$route.query, roles },
    });
  }

  async loadMoreMembers(): Promise<void> {
    const { roles, MEMBERS_PER_PAGE, group, page } = this;
    await this.$apollo.queries.members.fetchMore({
      // New variables
      variables() {
        return {
          name: usernameWithDomain(group),
          page,
          limit: MEMBERS_PER_PAGE,
          roles,
        };
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const oldMembers = previousResult.group.members;
        const newMembers = fetchMoreResult.group.members;
        return {
          elements: [...oldMembers.elements, ...newMembers.elements],
          total: newMembers.total,
          __typename: oldMembers.__typename,
        };
      },
    });
  }

  async removeMember(memberId: string): Promise<void> {
    const { roles, MEMBERS_PER_PAGE, group, page } = this;
    const variables = {
      name: usernameWithDomain(group),
      page,
      limit: MEMBERS_PER_PAGE,
      roles,
    };
    try {
      await this.$apollo.mutate<{ removeMember: IMember }>({
        mutation: REMOVE_MEMBER,
        variables: {
          groupId: this.group.id,
          memberId,
        },
        refetchQueries: [
          {
            query: GROUP_MEMBERS,
            variables,
          },
        ],
      });
      this.$notifier.success(
        this.$t("The member was removed from the group {group}", {
          username: this.newMemberUsername,
          group: this.group.name || usernameWithDomain(this.group),
        }) as string
      );
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }

  promoteMember(member: IMember): void {
    if (!member.id) return;
    if (member.role === MemberRole.MODERATOR) {
      this.updateMember(member.id, MemberRole.ADMINISTRATOR);
    }
    if (member.role === MemberRole.MEMBER) {
      this.updateMember(member.id, MemberRole.MODERATOR);
    }
  }

  demoteMember(member: IMember): void {
    if (!member.id) return;
    if (member.role === MemberRole.MODERATOR) {
      this.updateMember(member.id, MemberRole.MEMBER);
    }
    if (member.role === MemberRole.ADMINISTRATOR) {
      this.updateMember(member.id, MemberRole.MODERATOR);
    }
  }

  async updateMember(memberId: string, role: MemberRole): Promise<void> {
    try {
      await this.$apollo.mutate<{ updateMember: IMember }>({
        mutation: UPDATE_MEMBER,
        variables: {
          memberId,
          role,
        },
        refetchQueries: [
          {
            query: FETCH_GROUP,
            variables: { name: this.$route.params.preferredUsername },
          },
        ],
      });
      let successMessage;
      switch (role) {
        case MemberRole.MODERATOR:
          successMessage = "The member role was updated to moderator";
          break;
        case MemberRole.ADMINISTRATOR:
          successMessage = "The member role was updated to administrator";
          break;
        case MemberRole.MEMBER:
        default:
          successMessage = "The member role was updated to simple member";
      }
      this.$notifier.success(this.$t(successMessage) as string);
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }
}
</script>
