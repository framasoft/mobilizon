<template>
  <section class="card my-3" v-if="invitations && invitations.length > 0">
    <InvitationCard
      v-for="member in invitations"
      :key="member.id"
      :member="member"
      @accept="acceptInvitation"
      @reject="rejectInvitation"
    />
  </section>
</template>
<script lang="ts">
import { ACCEPT_INVITATION, REJECT_INVITATION } from "@/graphql/member";
import { Component, Prop, Vue } from "vue-property-decorator";
import InvitationCard from "@/components/Group/InvitationCard.vue";
import { PERSON_STATUS_GROUP } from "@/graphql/actor";
import { IMember } from "@/types/actor/member.model";
import { IGroup, IPerson, usernameWithDomain } from "@/types/actor";

@Component({
  components: {
    InvitationCard,
  },
})
export default class Invitations extends Vue {
  @Prop({ required: true, type: Array }) invitations!: IMember;

  async acceptInvitation(id: string): Promise<void> {
    try {
      await this.$apollo.mutate<{ acceptInvitation: IMember }>({
        mutation: ACCEPT_INVITATION,
        variables: {
          id,
        },
        refetchQueries({ data }) {
          const profile = data?.acceptInvitation?.actor as IPerson;
          const group = data?.acceptInvitation?.parent as IGroup;
          if (profile && group) {
            return [
              {
                query: PERSON_STATUS_GROUP,
                variables: { id: profile.id, group: usernameWithDomain(group) },
              },
            ];
          }
          return [];
        },
      });
    } catch (error: any) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }

  async rejectInvitation(id: string): Promise<void> {
    try {
      await this.$apollo.mutate<{ rejectInvitation: IMember }>({
        mutation: REJECT_INVITATION,
        variables: {
          id,
        },
        refetchQueries({ data }) {
          const profile = data?.rejectInvitation?.actor as IPerson;
          const group = data?.rejectInvitation?.parent as IGroup;
          if (profile && group) {
            return [
              {
                query: PERSON_STATUS_GROUP,
                variables: { id: profile.id, group: usernameWithDomain(group) },
              },
            ];
          }
          return [];
        },
      });
    } catch (error: any) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }
}
</script>
