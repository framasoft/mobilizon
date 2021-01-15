<template>
  <div class="container section">
    <b-notification v-if="$apollo.queries.interact.loading">
      {{ $t("Redirecting to content…") }}
    </b-notification>
    <b-notification v-if="$apollo.queries.interact.skip" type="is-danger">
      {{ $t("Resource provided is not an URL") }}
    </b-notification>
    <b-message
      :title="$t('Error')"
      type="is-danger"
      has-icon
      :closable="false"
      v-if="!$apollo.loading && errors.length > 0"
    >
      <p v-for="error in errors" :key="error">
        <b>{{ error }}</b>
      </p>
      <p>
        {{
          $t(
            "It is possible that the content is not accessible on this instance, because this instance has blocked the profiles or groups behind this content."
          )
        }}
      </p>
    </b-message>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { INTERACT } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import { IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../router/name";

@Component({
  apollo: {
    interact: {
      query: INTERACT,
      variables() {
        return {
          uri: this.$route.query.uri,
        };
      },
      skip() {
        try {
          const url = this.$route.query.uri as string;
          const uri = new URL(url);
          return !(uri instanceof URL);
        } catch (e) {
          return true;
        }
      },
      error({ graphQLErrors, networkError }) {
        if (networkError) {
          this.errors = [networkError.message];
        }
        this.errors = graphQLErrors.map((error) => error.message);
      },
      async result({ data: { interact } }) {
        switch (interact.__typename) {
          case "Group":
            await this.$router.replace({
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(interact) },
            });
            break;
          case "Event":
            await this.$router.replace({
              name: RouteName.EVENT,
              params: { uuid: interact.uuid },
            });
            break;
          default:
            this.error = [this.$t("This URL is not supported")];
        }
        // await this.$router.replace({
        //   name: RouteName.EVENT,
        //   params: { uuid: event.uuid },
        // });
      },
    },
  },
})
export default class Interact extends Vue {
  interact!: IEvent | IGroup;

  errors: string[] = [];
}
</script>
<style lang="scss">
main > .container {
  background: $white;
}
</style>
