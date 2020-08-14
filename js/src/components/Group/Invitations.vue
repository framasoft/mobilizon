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
import { IMember } from "@/types/actor";
import { Component, Prop, Vue } from "vue-property-decorator";
import InvitationCard from "@/components/Group/InvitationCard.vue";

@Component({
  components: {
    InvitationCard,
  },
})
export default class Invitations extends Vue {
  @Prop({ required: true, type: Array }) invitations!: IMember;

  async acceptInvitation(id: string) {
    const { data } = await this.$apollo.mutate<{ acceptInvitation: IMember }>({
      mutation: ACCEPT_INVITATION,
      variables: {
        id,
      },
    });
    if (data) {
      this.$emit("acceptInvitation", data.acceptInvitation);
    }
  }

  async rejectInvitation(id: string) {
    const { data } = await this.$apollo.mutate<{ rejectInvitation: IMember }>({
      mutation: REJECT_INVITATION,
      variables: {
        id,
      },
    });
    if (data) {
      this.$emit("rejectInvitation", data.rejectInvitation);
    }
  }
}
</script>
