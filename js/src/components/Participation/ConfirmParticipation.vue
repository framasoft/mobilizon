<template>
  <section class="container">
    <h1 class="title" v-if="loading">{{ $t("Your participation is being validated") }}</h1>
    <div v-else>
      <div v-if="failed">
        <b-message :title="$t('Error while validating participation')" type="is-danger">
          {{
            $t(
              "Either the participation has already been validated, either the validation token is incorrect."
            )
          }}
        </b-message>
      </div>
      <h1 class="title" v-else>{{ $t("Your participation has been validated") }}</h1>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import RouteName from "../../router/name";
import { IParticipant } from "../../types/event.model";
import { CONFIRM_PARTICIPATION } from "../../graphql/event";
import { confirmLocalAnonymousParticipation } from "../../services/AnonymousParticipationStorage";

@Component
export default class ConfirmParticipation extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;

  failed = false;

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
        await confirmLocalAnonymousParticipation(participation.event.uuid);
        await this.$router.replace({
          name: RouteName.EVENT,
          params: { uuid: data.confirmParticipation.event.uuid },
        });
      }
    } catch (err) {
      console.error(err);

      Snackbar.open({ message: err.message, type: "is-danger", position: "is-bottom" });
      this.failed = true;
    } finally {
      this.loading = false;
    }
  }
}
</script>
