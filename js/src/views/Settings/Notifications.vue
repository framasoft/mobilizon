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
    </section>
    <section>
      <div class="setting-title">
        <h2>{{ $t("Organizer notifications") }}</h2>
      </div>
      <div class="field">
        <strong>{{ $t("Notifications for manually approved participations to an event") }}</strong>
        <b-select
          v-model="notificationPendingParticipation"
          @input="updateSetting({ notificationPendingParticipation })"
        >
          <option
            v-for="(value, key) in notificationPendingParticipationValues"
            :value="key"
            :key="key"
            >{{ value }}</option
          >
        </b-select>
        <p>
          {{ $t("We'll send you an email when there new participations requests.") }}
        </p>
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

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
  },
})
export default class Notifications extends Vue {
  loggedUser!: ICurrentUser;

  notificationOnDay = true;

  notificationEachWeek = false;

  notificationBeforeEvent = false;

  notificationPendingParticipation = INotificationPendingParticipationEnum.NONE;

  notificationPendingParticipationValues: object = {};

  mounted() {
    this.notificationPendingParticipationValues = {
      [INotificationPendingParticipationEnum.NONE]: this.$t("No notifications"),
      [INotificationPendingParticipationEnum.DIRECT]: this.$t("Direct"),
      [INotificationPendingParticipationEnum.ONE_HOUR]: this.$t("Every hour"),
      [INotificationPendingParticipationEnum.ONE_DAY]: this.$t("Every day"),
    };
  }

  async updateSetting(variables: object) {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
    });
  }
}
</script>
