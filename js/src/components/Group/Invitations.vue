<template>
  <section v-if="invitations && invitations.length > 0">
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
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { IMember } from "@/types/actor/member.model";

@Component({
  components: {
    InvitationCard,
  },
})
export default class Invitations extends Vue {
  @Prop({ required: true, type: Array }) invitations!: IMember;

  async acceptInvitation(id: string): Promise<void> {
    try {
      const { data } = await this.$apollo.mutate<{ acceptInvitation: IMember }>(
        {
          mutation: ACCEPT_INVITATION,
          variables: {
            id,
          },
          refetchQueries: [{ query: LOGGED_USER_MEMBERSHIPS }],
        }
      );
      if (data) {
        this.$emit("accept-invitation", data.acceptInvitation);
      }
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }

  async rejectInvitation(id: string): Promise<void> {
    try {
      const { data } = await this.$apollo.mutate<{ rejectInvitation: IMember }>(
        {
          mutation: REJECT_INVITATION,
          variables: {
            id,
          },
          refetchQueries: [{ query: LOGGED_USER_MEMBERSHIPS }],
        }
      );
      if (data) {
        this.$emit("reject-invitation", data.rejectInvitation);
      }
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }
}
</script>
