<template>
  <div v-if="loggedUser">
    <section>
      <div class="setting-title">
        <h2>{{ $t("Participation notifications") }}</h2>
      </div>
      <div class="field">
        <strong>{{
          $t(
            "Mobilizon will send you an email when the events you are attending have important changes: date and time, address, confirmation or cancellation, etc."
          )
        }}</strong>
        <p>
          {{ $t("Other notification options:") }}
        </p>
      </div>
      <div class="field">
        <b-checkbox
          v-model="notificationOnDay"
          @input="updateSetting({ notificationOnDay })"
        >
          <strong>{{ $t("Notification on the day of the event") }}</strong>
          <p>
            {{
              $t(
                "We'll use your timezone settings to send a recap of the morning of the event."
              )
            }}
          </p>
        </b-checkbox>
      </div>
      <p>
        {{
          $t(
            "To activate more notifications, head over to the notification settings."
          )
        }}
      </p>
    </section>
  </div>
</template>
<script lang="ts">
import { Component } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { mixins } from "vue-class-component";
import Onboarding from "../../mixins/onboarding";

@Component
export default class NotificationsOnboarding extends mixins(Onboarding) {
  notificationOnDay = true;

  mounted(): void {
    this.doUpdateSetting({
      notificationOnDay: true,
      notificationEachWeek: false,
      notificationBeforeEvent: false,
    });
  }

  async updateSetting(variables: Record<string, unknown>): Promise<void> {
    try {
      this.doUpdateSetting(variables);
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }
}
</script>
