<template>
  <section class="section container">
    <h1 class="title" v-if="loading">
      {{ $t("Your participation request is being validated") }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message
          :title="$t('Error while validating participation request')"
          type="is-danger"
        >
          {{
            $t(
              "Either the participation request has already been validated, either the validation token is incorrect."
            )
          }}
        </b-message>
      </div>
      <div v-else>
        <h1 class="title">
          {{ $t("Your participation request has been validated") }}
        </h1>
        <p
          class="content"
          v-if="participation.event.joinOptions == EventJoinOptions.RESTRICTED"
        >
          {{
            $t("Your participation still has to be approved by the organisers.")
          }}
        </p>
        <div class="columns has-text-centered">
          <div class="column">
            <router-link
              native-type="button"
              tag="a"
              class="button is-primary is-large"
              :to="{
                name: RouteName.EVENT,
                params: { uuid: this.participation.event.uuid },
              }"
              >{{ $t("Go to the event page") }}</router-link
            >
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { confirmLocalAnonymousParticipation } from "@/services/AnonymousParticipationStorage";
import { EventJoinOptions } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import RouteName from "../../router/name";
import { CONFIRM_PARTICIPATION } from "../../graphql/event";

@Component
export default class ConfirmParticipation extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;

  failed = false;

  participation!: IParticipant;

  EventJoinOptions = EventJoinOptions;

  RouteName = RouteName;

  async created(): Promise<void> {
    await this.validateAction();
  }

  async validateAction(): Promise<void> {
    try {
      const { data } = await this.$apollo.mutate<{
        confirmParticipation: IParticipant;
      }>({
        mutation: CONFIRM_PARTICIPATION,
        variables: {
          token: this.token,
        },
      });

      if (data) {
        const { confirmParticipation: participation } = data;
        this.participation = participation;
        await confirmLocalAnonymousParticipation(this.participation.event.uuid);
      }
    } catch (err) {
      console.error(err);
      this.failed = true;
    } finally {
      this.loading = false;
    }
  }
}
</script>
