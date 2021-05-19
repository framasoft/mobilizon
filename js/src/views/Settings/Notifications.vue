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
            $t("Notifications")
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
    <section>
      <div class="setting-title">
        <h2>{{ $t("Personal feeds") }}</h2>
      </div>
      <p>
        {{
          $t(
            "These feeds contain event data for the events for which any of your profiles is a participant or creator. You should keep these private. You can find feeds for specific profiles on each profile edition page."
          )
        }}
      </p>
      <div v-if="feedTokens && feedTokens.length > 0">
        <div
          class="buttons"
          v-for="feedToken in feedTokens"
          :key="feedToken.token"
        >
          <b-tooltip
            :label="$t('URL copied to clipboard')"
            :active="showCopiedTooltip.atom"
            always
            type="is-success"
            position="is-left"
          >
            <b-button
              tag="a"
              icon-left="rss"
              @click="
                (e) => copyURL(e, tokenToURL(feedToken.token, 'atom'), 'atom')
              "
              :href="tokenToURL(feedToken.token, 'atom')"
              target="_blank"
              >{{ $t("RSS/Atom Feed") }}</b-button
            >
          </b-tooltip>
          <b-tooltip
            :label="$t('URL copied to clipboard')"
            :active="showCopiedTooltip.ics"
            always
            type="is-success"
            position="is-left"
          >
            <b-button
              tag="a"
              @click="
                (e) => copyURL(e, tokenToURL(feedToken.token, 'ics'), 'ics')
              "
              icon-left="calendar-sync"
              :href="tokenToURL(feedToken.token, 'ics')"
              target="_blank"
              >{{ $t("ICS/WebCal Feed") }}</b-button
            >
          </b-tooltip>
          <b-button
            icon-left="refresh"
            type="is-text"
            @click="openRegenerateFeedTokensConfirmation"
            >{{ $t("Regenerate new links") }}</b-button
          >
        </div>
      </div>
      <div v-else>
        <b-button
          icon-left="refresh"
          type="is-text"
          @click="generateFeedTokens"
          >{{ $t("Create new links") }}</b-button
        >
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { INotificationPendingEnum } from "@/types/enums";
import {
  USER_SETTINGS,
  SET_USER_SETTINGS,
  FEED_TOKENS_LOGGED_USER,
} from "../../graphql/user";
import { IUser } from "../../types/current-user.model";
import RouteName from "../../router/name";
import { IFeedToken } from "@/types/feedtoken.model";
import { CREATE_FEED_TOKEN, DELETE_FEED_TOKEN } from "@/graphql/feed_tokens";

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
    feedTokens: {
      query: FEED_TOKENS_LOGGED_USER,
      update: (data) =>
        data.loggedUser.feedTokens.filter(
          (token: IFeedToken) => token.actor === null
        ),
    },
  },
})
export default class Notifications extends Vue {
  loggedUser!: IUser;

  feedTokens: IFeedToken[] = [];

  notificationOnDay: boolean | undefined = true;

  notificationEachWeek: boolean | undefined = false;

  notificationBeforeEvent: boolean | undefined = false;

  notificationPendingParticipation: INotificationPendingEnum | undefined =
    INotificationPendingEnum.NONE;

  notificationPendingParticipationValues: Record<string, unknown> = {};

  RouteName = RouteName;

  showCopiedTooltip = { ics: false, atom: false };

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
      this.notificationBeforeEvent =
        this.loggedUser.settings.notificationBeforeEvent;
      this.notificationPendingParticipation =
        this.loggedUser.settings.notificationPendingParticipation;
    }
  }

  async updateSetting(variables: Record<string, unknown>): Promise<void> {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
      refetchQueries: [{ query: USER_SETTINGS }],
    });
  }

  tokenToURL(token: string, format: string): string {
    return `${window.location.origin}/events/going/${token}/${format}`;
  }

  copyURL(e: Event, url: string, format: "ics" | "atom"): void {
    if (navigator.clipboard) {
      e.preventDefault();
      navigator.clipboard.writeText(url);
      this.showCopiedTooltip[format] = true;
      setTimeout(() => {
        this.showCopiedTooltip[format] = false;
      }, 2000);
    }
  }

  openRegenerateFeedTokensConfirmation(): void {
    this.$buefy.dialog.confirm({
      type: "is-warning",
      title: this.$t("Regenerate new links") as string,
      message: this.$t(
        "You'll need to change the URLs where there were previously entered."
      ) as string,
      confirmText: this.$t("Regenerate new links") as string,
      cancelText: this.$t("Cancel") as string,
      onConfirm: () => this.regenerateFeedTokens(),
    });
  }

  async regenerateFeedTokens(): Promise<void> {
    if (this.feedTokens.length < 1) return;
    await this.deleteFeedToken(this.feedTokens[0].token);
    const newToken = await this.createNewFeedToken();
    this.feedTokens.pop();
    this.feedTokens.push(newToken);
  }

  async generateFeedTokens(): Promise<void> {
    const newToken = await this.createNewFeedToken();
    this.feedTokens.push(newToken);
  }

  private async deleteFeedToken(token: string): Promise<void> {
    await this.$apollo.mutate({
      mutation: DELETE_FEED_TOKEN,
      variables: { token },
    });
  }

  private async createNewFeedToken(): Promise<IFeedToken> {
    const { data } = await this.$apollo.mutate({
      mutation: CREATE_FEED_TOKEN,
    });

    return data.createFeedToken;
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

::v-deep .buttons > *:not(:last-child) .button {
  margin-right: 0.5rem;
}
</style>
