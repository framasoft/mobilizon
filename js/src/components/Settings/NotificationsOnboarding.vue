<template>
  <div v-if="loggedUser">
    <section>
      <div class="setting-title">
        <h2>{{ $t("Participation notifications") }}</h2>
      </div>
      <div class="field">
        <strong>{{
          $t("We'll always send you emails to notify about important event updates")
        }}</strong>
        <p>
          {{
            $t(
              "Like title or physical address update, start or end date change or event being confirmed or cancelled."
            )
          }}
        </p>
      </div>
      <div class="field">
        <b-checkbox v-model="notificationOnDay" @input="updateSetting({ notificationOnDay })">
          <strong>{{ $t("Notification on the day of the event") }}</strong>
          <p>
            {{
              $t("We'll use your timezone settings to send a recap of the morning of the event.")
            }}
          </p>
        </b-checkbox>
      </div>
      <p>{{ $t("To activate more notifications, head over to the notification settings.") }}</p>
      <div class="has-text-centered">
        <router-link
          :to="{ name: RouteName.NOTIFICATIONS }"
          class="button is-primary is-outlined"
          >{{ $t("Manage my notifications") }}</router-link
        >
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import {
  ICurrentUser,
  INotificationPendingParticipationEnum,
} from "../../types/current-user.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
  },
})
export default class NotificationsOnboarding extends Vue {
  loggedUser!: ICurrentUser;

  notificationOnDay = true;

  RouteName = RouteName;

  async updateSetting(variables: object) {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
    });
  }
}
</script>
