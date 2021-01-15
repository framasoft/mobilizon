<template>
  <redirect-with-account
    v-if="uri"
    :uri="uri"
    :pathAfterLogin="`/events/${uuid}`"
    :sentence="sentence"
  />
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import { FETCH_EVENT } from "@/graphql/event";
import { IEvent } from "@/types/event.model";

@Component({
  components: { RedirectWithAccount },
  apollo: {
    event: {
      query: FETCH_EVENT,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          uuid: this.uuid,
        };
      },
      skip() {
        return !this.uuid;
      },
    },
  },
})
export default class ParticipationWithAccount extends Vue {
  @Prop({ type: String, required: true }) uuid!: string;

  event!: IEvent;

  get uri(): string | undefined {
    return this.event?.url;
  }

  sentence = this.$t(
    "We will redirect you to your instance in order to interact with this event"
  );
}
</script>
