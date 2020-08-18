<template>
  <section class="section container">
    <h1 class="title">{{ $t("My groups") }}</h1>
    <router-link :to="{ name: RouteName.CREATE_GROUP }">{{ $t("Create group") }}</router-link>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <invitations
      :invitations="invitations"
      @acceptInvitation="acceptInvitation"
      @rejectInvitation="rejectInvitation"
    />
    <section v-if="memberships && memberships.length > 0">
      <GroupMemberCard v-for="member in memberships" :key="member.id" :member="member" />
    </section>
    <b-message v-if="$apollo.loading === false && memberships.length === 0" type="is-danger">
      {{ $t("No groups found") }}
    </b-message>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import GroupMemberCard from "@/components/Group/GroupMemberCard.vue";
import Invitations from "@/components/Group/Invitations.vue";
import { Paginate } from "@/types/paginate";
import { IGroup, IMember, MemberRole, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";
import { ACCEPT_INVITATION } from "../../graphql/member";

@Component({
  components: {
    GroupMemberCard,
    Invitations,
  },
  apollo: {
    membershipsPages: {
      query: LOGGED_USER_MEMBERSHIPS,
      fetchPolicy: "network-only",
      variables: {
        page: 1,
        limit: 10,
        beforeDateTime: new Date().toISOString(),
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
export default class MyEvents extends Vue {
  membershipsPages!: Paginate<IMember>;

  RouteName = RouteName;

  acceptInvitation(member: IMember) {
    return this.$router.push({
      name: RouteName.GROUP,
      params: { preferredUsername: usernameWithDomain(member.parent) },
    });
  }

  rejectInvitation({ id: memberId }: { id: string }) {
    const index = this.membershipsPages.elements.findIndex(
      (membership) => membership.role === MemberRole.INVITED && membership.id === memberId
    );
    if (index > -1) {
      this.membershipsPages.elements.splice(index, 1);
      this.membershipsPages.total -= 1;
    }
  }

  get invitations() {
    if (!this.membershipsPages) return [];
    return this.membershipsPages.elements.filter(
      (member: IMember) => member.role === MemberRole.INVITED
    );
  }

  get memberships() {
    if (!this.membershipsPages) return [];
    return this.membershipsPages.elements.filter(
      (member: IMember) => member.role !== MemberRole.INVITED
    );
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
@import "../../variables";

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
</style>
