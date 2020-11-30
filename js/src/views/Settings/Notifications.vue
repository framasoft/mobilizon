<template>
  <div v-if="loggedUser">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ACCOUNT_SETTINGS }">{{
            $t("Account")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.NOTIFICATIONS }">{{
            $t("Email notifications")
          }}</router-link>
        </li>
      </ul>
    </nav>
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
      </div>
      <p>
        {{ $t("Other notification options:") }}
      </p>
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
          <div v-if="loggedUser.settings && loggedUser.settings.timezone">
            <em>{{
              $t("Your timezone is currently set to {timezone}.", {
                timezone: loggedUser.settings.timezone,
              })
            }}</em>
            <router-link
              class="change-timezone"
              :to="{ name: RouteName.PREFERENCES }"
              >{{ $t("Change timezone") }}</router-link
            >
          </div>
          <span v-else>{{
            $t("You can pick your timezone into your preferences.")
          }}</span>
        </b-checkbox>
      </div>
      <div class="field">
        <b-checkbox
          v-model="notificationEachWeek"
          @input="updateSetting({ notificationEachWeek })"
        >
          <strong>{{ $t("Recap every week") }}</strong>
          <p>
            {{
              $t(
                "You'll get a weekly recap every Monday for upcoming events, if you have any."
              )
            }}
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
      <div class="field is-primary">
        <strong>{{
          $t("Notifications for manually approved participations to an event")
        }}</strong>
        <p>
          {{
            $t(
              "If you have opted for manual validation of participants, Mobilizon will send you an email to inform you of new participations to be processed. You can choose the frequency of these notifications below."
            )
          }}
        </p>
        <b-select
          v-model="notificationPendingParticipation"
          @input="updateSetting({ notificationPendingParticipation })"
        >
          <option
            v-for="(value, key) in notificationPendingParticipationValues"
            :value="key"
            :key="key"
          >
            {{ value }}
          </option>
        </b-select>
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { INotificationPendingEnum } from "@/types/enums";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import { IUser } from "../../types/current-user.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
  },
})
export default class Notifications extends Vue {
  loggedUser!: IUser;

  notificationOnDay = true;

  notificationEachWeek = false;

  notificationBeforeEvent = false;

  notificationPendingParticipation = INotificationPendingEnum.NONE;

  notificationPendingParticipationValues: Record<string, unknown> = {};

  RouteName = RouteName;

  mounted(): void {
    this.notificationPendingParticipationValues = {
      [INotificationPendingEnum.NONE]: this.$t("Do not receive any mail"),
      [INotificationPendingEnum.DIRECT]: this.$t(
        "Receive one email per request"
      ),
      [INotificationPendingEnum.ONE_HOUR]: this.$t("Hourly email summary"),
      [INotificationPendingEnum.ONE_DAY]: this.$t("Daily email summary"),
    };
  }

  @Watch("loggedUser")
  setSettings(): void {
    if (this.loggedUser && this.loggedUser.settings) {
      this.notificationOnDay = this.loggedUser.settings.notificationOnDay;
      this.notificationEachWeek = this.loggedUser.settings.notificationEachWeek;
      this.notificationBeforeEvent = this.loggedUser.settings.notificationBeforeEvent;
      this.notificationPendingParticipation = this.loggedUser.settings.notificationPendingParticipation;
    }
  }

  async updateSetting(variables: Record<string, unknown>): Promise<void> {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
      refetchQueries: [{ query: USER_SETTINGS }],
    });
  }
}
</script>

<style lang="scss" scoped>
.field {
  &:not(:last-child) {
    margin-bottom: 1.5rem;
  }

  a.change-timezone {
    color: $primary;
    text-decoration: underline;
    text-decoration-color: #fea72b;
    text-decoration-thickness: 2px;
    margin-left: 5px;
  }
}
</style>
