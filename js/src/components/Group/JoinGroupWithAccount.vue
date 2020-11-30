<template>
  <redirect-with-account
    :uri="uri"
    :pathAfterLogin="`/@${preferredUsername}`"
    :sentence="sentence"
  />
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import RouteName from "../../router/name";

@Component({
  components: { RedirectWithAccount },
})
export default class JoinGroupWithAccount extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  get uri(): string {
    return `${window.location.origin}${
      this.$router.resolve({
        name: RouteName.GROUP,
        params: { preferredUsername: this.preferredUsername },
      }).href
    }`;
  }

  sentence = this.$t(
    "We will redirect you to your instance in order to interact with this group"
  );
}
</script>
