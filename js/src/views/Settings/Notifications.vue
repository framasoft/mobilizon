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
        <h2>{{ $t("Browser notifications") }}</h2>
      </div>
      <b-button v-if="subscribed" @click="unsubscribeToWebPush()">{{
        $t("Unsubscribe to browser notifications")
      }}</b-button>
      <b-button
        icon-left="rss"
        @click="subscribeToWebPush"
        v-else-if="canShowWebPush()"
        >{{ $t("Activate browser notification") }}</b-button
      >
      <span v-else>{{
        $t("You can't use notifications in this browser.")
      }}</span>
    </section>
    <section>
      <div class="setting-title">
        <h2>{{ $t("Notification settings") }}</h2>
      </div>
      <p>
        {{
          $t(
            "Select the activities for which you wish to receive an email or a push notification."
          )
        }}
      </p>
      <table class="table">
        <tbody>
          <template v-for="notificationType in notificationTypes">
            <tr :key="`${notificationType.label}-title`">
              <th colspan="3">
                {{ notificationType.label }}
              </th>
            </tr>
            <tr :key="`${notificationType.label}-subtitle`">
              <th v-for="(method, key) in notificationMethods" :key="key">
                {{ method }}
              </th>
              <th></th>
            </tr>
            <tr v-for="subType in notificationType.subtypes" :key="subType.id">
              <td v-for="(method, key) in notificationMethods" :key="key">
                <b-checkbox
                  :value="notificationValues[subType.id][key]"
                  @input="(e) => updateNotificationValue(subType.id, key, e)"
                  :disabled="notificationValues[subType.id].disabled"
                />
              </td>
              <td>
                {{ subType.label }}
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </section>
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
  SET_USER_SETTINGS,
  FEED_TOKENS_LOGGED_USER,
  USER_NOTIFICATIONS,
  UPDATE_ACTIVITY_SETTING,
} from "../../graphql/user";
import { IUser } from "../../types/current-user.model";
import RouteName from "../../router/name";
import { IFeedToken } from "@/types/feedtoken.model";
import { CREATE_FEED_TOKEN, DELETE_FEED_TOKEN } from "@/graphql/feed_tokens";
import {
  subscribeUserToPush,
  unsubscribeUserToPush,
} from "../../services/push-subscription";
import {
  REGISTER_PUSH_MUTATION,
  UNREGISTER_PUSH_MUTATION,
} from "@/graphql/webPush";
import { merge } from "lodash";

type NotificationSubType = { label: string; id: string };
type NotificationType = { label: string; subtypes: NotificationSubType[] };

@Component({
  apollo: {
    loggedUser: USER_NOTIFICATIONS,
    feedTokens: {
      query: FEED_TOKENS_LOGGED_USER,
      update: (data) =>
        data.loggedUser.feedTokens.filter(
          (token: IFeedToken) => token.actor === null
        ),
    },
  },
  metaInfo() {
    return {
      title: this.$t("Notifications") as string,
    };
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

  subscribed = false;

  notificationMethods = {
    email: this.$t("Email") as string,
    push: this.$t("Push") as string,
  };

  defaultNotificationValues = {
    participation_event_updated: {
      email: true,
      push: true,
      disabled: true,
    },
    participation_event_comment: {
      email: true,
      push: true,
    },
    event_new_pending_participation: {
      email: true,
      push: true,
    },
    event_new_participation: {
      email: false,
      push: false,
    },
    event_created: {
      email: false,
      push: false,
    },
    event_updated: {
      email: false,
      push: false,
    },
    discussion_updated: {
      email: false,
      push: false,
    },
    post_published: {
      email: false,
      push: false,
    },
    post_updated: {
      email: false,
      push: false,
    },
    resource_updated: {
      email: false,
      push: false,
    },
    member_request: {
      email: true,
      push: true,
    },
    member_updated: {
      email: false,
      push: false,
    },
    user_email_password_updated: {
      email: true,
      push: false,
      disabled: true,
    },
    event_comment_mention: {
      email: true,
      push: true,
    },
    discussion_mention: {
      email: true,
      push: false,
    },
    event_new_comment: {
      email: true,
      push: false,
    },
  };

  notificationTypes: NotificationType[] = [
    {
      label: this.$t("Mentions") as string,
      subtypes: [
        {
          id: "event_comment_mention",
          label: this.$t(
            "I've been mentionned in a comment under an event"
          ) as string,
        },
        {
          id: "discussion_mention",
          label: this.$t(
            "I've been mentionned in a group discussion"
          ) as string,
        },
      ],
    },
    {
      label: this.$t("Participations") as string,
      subtypes: [
        {
          id: "participation_event_updated",
          label: this.$t("An event I'm going to has been updated") as string,
        },
        {
          id: "participation_event_comment",
          label: this.$t(
            "An event I'm going to has posted an announcement"
          ) as string,
        },
      ],
    },
    {
      label: this.$t("Organizers") as string,
      subtypes: [
        {
          id: "event_new_pending_participation",
          label: this.$t(
            "An event I'm organizing has a new pending participation"
          ) as string,
        },
        {
          id: "event_new_participation",
          label: this.$t(
            "An event I'm organizing has a new participation"
          ) as string,
        },
        {
          id: "event_new_comment",
          label: this.$t("An event I'm organizing has a new comment") as string,
        },
      ],
    },
    {
      label: this.$t("Group activity") as string,
      subtypes: [
        {
          id: "event_created",
          label: this.$t(
            "An event from one of my groups has been published"
          ) as string,
        },
        {
          id: "event_updated",
          label: this.$t(
            "An event from one of my groups has been updated or deleted"
          ) as string,
        },
        {
          id: "discussion_updated",
          label: this.$t("A discussion has been created or updated") as string,
        },
        {
          id: "post_published",
          label: this.$t("A post has been published") as string,
        },
        {
          id: "post_updated",
          label: this.$t("A post has been updated") as string,
        },
        {
          id: "resource_updated",
          label: this.$t("A resource has been created or updated") as string,
        },
        {
          id: "member_request",
          label: this.$t(
            "A member requested to join one of my groups"
          ) as string,
        },
        {
          id: "member_updated",
          label: this.$t("A member has been updated") as string,
        },
      ],
    },
    {
      label: this.$t("User settings") as string,
      subtypes: [
        {
          id: "user_email_password_updated",
          label: this.$t("You changed your email or password") as string,
        },
      ],
    },
  ];

  get userNotificationValues(): Record<string, Record<string, boolean>> {
    return this.loggedUser.activitySettings.reduce((acc, activitySetting) => {
      acc[activitySetting.key] = acc[activitySetting.key] || {};
      acc[activitySetting.key][activitySetting.method] =
        activitySetting.enabled;
      return acc;
    }, {} as Record<string, Record<string, boolean>>);
  }

  get notificationValues(): Record<string, Record<string, boolean>> {
    return merge(this.defaultNotificationValues, this.userNotificationValues);
  }

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
      refetchQueries: [{ query: USER_NOTIFICATIONS }],
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

  async subscribeToWebPush(): Promise<void> {
    try {
      if (this.canShowWebPush()) {
        const subscription = await subscribeUserToPush();
        if (subscription) {
          const subscriptionJSON = subscription?.toJSON();
          console.log("subscription", subscriptionJSON);
          const { data } = await this.$apollo.mutate({
            mutation: REGISTER_PUSH_MUTATION,
            variables: {
              endpoint: subscriptionJSON.endpoint,
              auth: subscriptionJSON?.keys?.auth,
              p256dh: subscriptionJSON?.keys?.p256dh,
            },
          });
          this.subscribed = true;
          console.log(data);
        }
      } else {
        console.log("can't do webpush");
      }
    } catch (e) {
      console.error(e);
    }
  }

  async unsubscribeToWebPush(): Promise<void> {
    try {
      const endpoint = await unsubscribeUserToPush();
      if (endpoint) {
        const { data } = await this.$apollo.mutate({
          mutation: UNREGISTER_PUSH_MUTATION,
          variables: {
            endpoint,
          },
        });
        console.log(data);
        this.subscribed = false;
      }
    } catch (e) {
      console.error(e);
    }
  }

  canShowWebPush(): boolean {
    return window.isSecureContext && !!navigator.serviceWorker;
  }

  async created(): Promise<void> {
    this.subscribed = await this.isSubscribed();
  }

  async updateNotificationValue(
    key: string,
    method: string,
    enabled: boolean
  ): Promise<void> {
    await this.$apollo.mutate({
      mutation: UPDATE_ACTIVITY_SETTING,
      variables: {
        key,
        method,
        enabled,
        userId: this.loggedUser.id,
      },
    });
  }

  private async isSubscribed(): Promise<boolean> {
    if (!("serviceWorker" in navigator)) return Promise.resolve(false);
    const registration = await navigator.serviceWorker.getRegistration();
    return (await registration?.pushManager.getSubscription()) != null;
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
