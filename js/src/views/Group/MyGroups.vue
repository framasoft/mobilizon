<template>
  <section class="section container">
    <h1 class="title">{{ $t("My groups") }}</h1>
    <p>
      {{
        $t(
          "Groups are spaces for coordination and preparation to better organize events and manage your community."
        )
      }}
    </p>
    <div class="buttons">
      <router-link class="button is-primary" :to="{ name: RouteName.CREATE_GROUP }">{{
        $t("Create group")
      }}</router-link>
    </div>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <invitations
      :invitations="invitations"
      @accept-invitation="acceptInvitation"
      @reject-invitation="rejectInvitation"
    />
    <section v-if="memberships && memberships.length > 0">
      <GroupMemberCard
        class="group-member-card"
        v-for="member in memberships"
        :key="member.id"
        :member="member"
        @leave="leaveGroup(member.parent)"
      />
      <b-pagination
        :total="membershipsPages.total"
        v-model="page"
        :per-page="limit"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      >
      </b-pagination>
    </section>
    <b-message v-if="$apollo.loading === false && memberships.length === 0" type="is-danger">
      {{ $t("No groups found") }}
    </b-message>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { LEAVE_GROUP } from "@/graphql/group";
import GroupMemberCard from "@/components/Group/GroupMemberCard.vue";
import Invitations from "@/components/Group/Invitations.vue";
import { Paginate } from "@/types/paginate";
import { IGroup, IMember, MemberRole, usernameWithDomain } from "@/types/actor";
import { Route } from "vue-router";
import RouteName from "../../router/name";

@Component({
  components: {
    GroupMemberCard,
    Invitations,
  },
  apollo: {
    membershipsPages: {
      query: LOGGED_USER_MEMBERSHIPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          page: this.page,
          limit: this.limit,
        };
      },
      update: (data) => data.loggedUser.memberships,
    },
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t("My groups") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class MyGroups extends Vue {
  membershipsPages!: Paginate<IMember>;

  RouteName = RouteName;

  page = 1;

  limit = 10;

  acceptInvitation(member: IMember): Promise<Route> {
    return this.$router.push({
      name: RouteName.GROUP,
      params: { preferredUsername: usernameWithDomain(member.parent) },
    });
  }

  rejectInvitation({ id: memberId }: { id: string }): void {
    const index = this.membershipsPages.elements.findIndex(
      (membership) => membership.role === MemberRole.INVITED && membership.id === memberId
    );
    if (index > -1) {
      this.membershipsPages.elements.splice(index, 1);
      this.membershipsPages.total -= 1;
    }
  }

  async leaveGroup(group: IGroup): Promise<void> {
    const { page, limit } = this;
    await this.$apollo.mutate({
      mutation: LEAVE_GROUP,
      variables: {
        groupId: group.id,
      },
      refetchQueries: [
        {
          query: LOGGED_USER_MEMBERSHIPS,
          variables: {
            page,
            limit,
          },
        },
      ],
    });
  }

  get invitations(): IMember[] {
    if (!this.membershipsPages) return [];
    return this.membershipsPages.elements.filter(
      (member: IMember) => member.role === MemberRole.INVITED
    );
  }

  get memberships(): IMember[] {
    if (!this.membershipsPages) return [];
    return this.membershipsPages.elements.filter(
      (member: IMember) => ![MemberRole.INVITED, MemberRole.REJECTED].includes(member.role)
    );
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
main > .container {
  background: $white;
}

.participation {
  margin: 1rem auto;
}

section {
  .upcoming-month {
    text-transform: capitalize;
  }
}

.group-member-card {
  margin-bottom: 1rem;
}
</style>
