<template>
  <redirect-with-account
    v-if="uri"
    :uri="uri"
    :pathAfterLogin="`/@${preferredUsername}`"
    :sentence="sentence"
  />
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import { FETCH_GROUP } from "@/graphql/group";
import { IGroup } from "@/types/actor";

@Component({
  components: { RedirectWithAccount },
  apollo: {
    group: {
      query: FETCH_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          beforeDateTime: null,
          afterDateTime: new Date(),
        };
      },
      skip() {
        return !this.$route.params.preferredUsername;
      },
    },
  },
})
export default class JoinGroupWithAccount extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  group!: IGroup;

  get uri(): string {
    return this.group?.url;
  }

  sentence = this.$t(
    "We will redirect you to your instance in order to interact with this group"
  );
}
</script>
