<template>
  <section class="section container">
    <h1 class="title">{{ $t("My groups") }}</h1>
    <router-link :to="{ name: RouteName.CREATE_GROUP }">{{ $t("Create group") }}</router-link>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <section v-if="invitations && invitations.length > 0">
      <InvitationCard
        v-for="member in invitations"
        :key="member.id"
        :member="member"
        @accept="acceptInvitation"
      />
    </section>
    <section v-if="memberships && memberships.length > 0">
      <GroupCard v-for="member in memberships" :key="member.id" :member="member" />
    </section>
    <b-message v-if="$apollo.loading === false && memberships.length === 0" type="is-danger">
      {{ $t("No groups found") }}
    </b-message>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import GroupCard from "@/components/Group/GroupCard.vue";
import InvitationCard from "@/components/Group/InvitationCard.vue";
import { Paginate } from "@/types/paginate";
import { IGroup, IMember, MemberRole } from "@/types/actor";
import RouteName from "../../router/name";
import { ACCEPT_INVITATION } from "../../graphql/member";

@Component({
  components: {
    GroupCard,
    InvitationCard,
  },
  apollo: {
    paginatedGroups: {
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
  paginatedGroups!: Paginate<IMember>;

  RouteName = RouteName;

  get invitations() {
    if (!this.paginatedGroups) return [];
    return this.paginatedGroups.elements.filter((member) => member.role === MemberRole.INVITED);
  }

  get memberships() {
    if (!this.paginatedGroups) return [];
    return this.paginatedGroups.elements.filter((member) => member.role !== MemberRole.INVITED);
  }

  async acceptInvitation(id: string) {
    await this.$apollo.mutate<{ acceptInvitation: IMember }>({
      mutation: ACCEPT_INVITATION,
      variables: {
        id,
      },
    });
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
