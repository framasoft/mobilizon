<template>
  <div v-if="loggedUser">
    <h2 class="subtitle">{{ $t("No notification settings yet") }}</h2>
    <div class="field">
      <b-checkbox disabled v-model="notificationEventUpdates">
        <strong>{{ $t("Important event updates") }}</strong>
        <p>
          {{
            $t("Like title update, start or end date change, event being confirmed or cancelled.")
          }}
        </p>
      </b-checkbox>
    </div>
    <div class="field">
      <b-checkbox v-model="notificationOnDay" @input="updateSetting({ notificationOnDay })">
        <strong>{{ $t("Notification on the day of the event") }}</strong>
        <p>
          {{ $t("We'll use your timezone settings to send a recap of the morning of the event.") }}
        </p>
        <span v-if="loggedUser.settings.timezone">{{
          $t("Your timezone is currently set to {timezone}.", {
            timezone: loggedUser.settings.timezone,
          })
        }}</span>
        <span v-else>{{ $t("You can pick your timezone into your preferences.") }}</span>
      </b-checkbox>
    </div>
    <div class="field">
      <b-checkbox v-model="notificationEachWeek" @input="updateSetting({ notificationEachWeek })">
        <strong>{{ $t("Recap every week") }}</strong>
        <p>
          {{ $t("You'll get a weekly recap every Monday for upcoming events, if you have any.") }}
        </p>
      </b-checkbox>
    </div>
    <div class="field">
      <b-checkbox
        v-model="notificationBeforeEvent"
        @input="updateSetting({ notificationBeforeEvent })"
      >
        <strong>{{ $t("Notification before the event") }}</strong>
        <p>
          {{
            $t(
              "We'll send you an email one hour before the event begins, to be sure you won't forget about it."
            )
          }}
        </p>
      </b-checkbox>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import { ICurrentUser } from "../../types/current-user.model";

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
  },
})
export default class Notifications extends Vue {
  loggedUser!: ICurrentUser;

  notificationEventUpdates = true;

  notificationOnDay = true;

  notificationEachWeek = false;

  notificationBeforeEvent = false;

  async updateSetting(variables: object) {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
    });
  }
}
</script>
