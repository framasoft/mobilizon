<template>
  <div class="container section">
    <b-notification v-if="$apollo.queries.searchEvents.loading">
      {{ $t("Redirecting to event…") }}
    </b-notification>
    <b-notification v-if="$apollo.queries.searchEvents.skip" type="is-danger">
      {{ $t("Resource provided is not an URL") }}
    </b-notification>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { SEARCH_EVENTS } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import RouteName from "../router/name";

@Component({
  apollo: {
    searchEvents: {
      query: SEARCH_EVENTS,
      variables() {
        return {
          searchText: this.$route.query.url,
        };
      },
      skip() {
        try {
          const url = this.$route.query.url as string;
          const uri = new URL(url);
          return !(uri instanceof URL);
        } catch (e) {
          return true;
        }
      },
      async result({ data }) {
        if (
          data.searchEvents &&
          data.searchEvents.total > 0 &&
          data.searchEvents.elements.length > 0
        ) {
          const event = data.searchEvents.elements[0];
          await this.$router.replace({
            name: RouteName.EVENT,
            params: { uuid: event.uuid },
          });
        }
      },
    },
  },
})
export default class Interact extends Vue {
  searchEvents!: IEvent[];

  RouteName = RouteName;
}
</script>
<style lang="scss">
main > .container {
  background: $white;
}
</style>
