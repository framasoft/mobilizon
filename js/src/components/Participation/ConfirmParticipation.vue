<template>
  <section class="section container">
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
      <div v-else>
        <h1 class="title">{{ $t("Your participation has been validated") }}</h1>
        <form @submit.prevent="askToSaveParticipation">
          <b-field>
            <b-checkbox v-model="saveParticipation">
              <b>{{ $t("Remember my participation in this browser") }}</b>
              <p>
                {{
                  $t(
                    "Will allow to display and manage your participation status on the event page when using this device. Uncheck if you're using a public device."
                  )
                }}
              </p>
            </b-checkbox>
          </b-field>
          <b-button native-type="submit" type="is-primary">{{ $t("Visit event page") }}</b-button>
        </form>
      </div>
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

  participation!: IParticipant;

  saveParticipation = true;

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
      }
    } catch (err) {
      console.error(err);

      Snackbar.open({ message: err.message, type: "is-danger", position: "is-bottom" });
      this.failed = true;
    } finally {
      this.loading = false;
    }
  }

  askToSaveParticipation(): void {
    if (this.saveParticipation) {
      this.saveParticipationInBrowser();
    }
    this.forwardToEventPage();
  }

  async saveParticipationInBrowser(): Promise<void> {
    await confirmLocalAnonymousParticipation(this.participation.event.uuid);
  }

  async forwardToEventPage(): Promise<void> {
    await this.$router.replace({
      name: RouteName.EVENT,
      params: { uuid: this.participation.event.uuid },
    });
  }
}
</script>
