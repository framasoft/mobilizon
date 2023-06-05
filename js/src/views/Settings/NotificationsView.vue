<template>
  <div v-if="loggedUser">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.ACCOUNT_SETTINGS,
          text: $t('Account'),
        },
        {
          name: RouteName.NOTIFICATIONS,
          text: $t('Notifications'),
        },
      ]"
    />
    <section class="my-4">
      <h2>{{ $t("Browser notifications") }}</h2>
      <o-button
        v-if="subscribed"
        @click="unsubscribeToWebPush()"
        @keyup.enter="unsubscribeToWebPush()"
        >{{ $t("Unsubscribe to browser push notifications") }}</o-button
      >
      <o-button
        icon-left="rss"
        @click="subscribeToWebPush"
        @keyup.enter="subscribeToWebPush"
        v-else-if="canShowWebPush && webPushEnabled"
        >{{ $t("Activate browser push notifications") }}</o-button
      >
      <o-notification variant="warning" v-else-if="!webPushEnabled">
        {{ $t("This instance hasn't got push notifications enabled.") }}
        <i18n-t keypath="Ask your instance admin to {enable_feature}.">
          <template #enable_feature>
            <a
              href="https://docs.joinmobilizon.org/administration/configure/push/"
              target="_blank"
              rel="noopener noreferer"
              >{{ $t("enable the feature") }}</a
            >
          </template>
        </i18n-t>
      </o-notification>
      <o-notification variant="danger" v-else>{{
        $t("You can't use push notifications in this browser.")
      }}</o-notification>
    </section>
    <section class="my-4">
      <h2>{{ $t("Notification settings") }}</h2>
      <p>
        {{
          $t(
            "Select the activities for which you wish to receive an email or a push notification."
          )
        }}
      </p>
      <table class="table table-auto">
        <tbody>
          <template
            v-for="notificationType in notificationTypes"
            :key="notificationType"
          >
            <tr>
              <th colspan="3">
                {{ notificationType.label }}
              </th>
            </tr>
            <tr>
              <th v-for="(method, key) in notificationMethods" :key="key">
                {{ method }}
              </th>
              <th>{{ $t("Description") }}</th>
            </tr>
            <tr v-for="subType in notificationType.subtypes" :key="subType.id">
              <td v-for="(method, key) in notificationMethods" :key="key">
                <o-checkbox
                  :value="notificationValues[subType.id][key].enabled"
                  @update:modelValue="
                    (e: boolean) =>
                      updateNotificationValue({
                        key: subType.id,
                        method: key,
                        enabled: e,
                      })
                  "
                  :disabled="notificationValues[subType.id][key].disabled"
                />
              </td>
              <td>
                {{ subType.label }}
              </td>
            </tr>
          </template>
        </tbody>
      </table>

      <o-field
        :label="$t('Send notification e-mails')"
        label-for="groupNotifications"
        :message="
          $t(
            'Announcements and mentions notifications are always sent straight away.'
          )
        "
      >
        <o-select
          v-model="groupNotifications"
          @input="updateSetting({ groupNotifications })"
          id="groupNotifications"
        >
          <option
            v-for="(value, key) in groupNotificationsValues"
            :value="key"
            :key="key"
          >
            {{ value }}
          </option>
        </o-select>
      </o-field>
    </section>
    <section class="my-4">
      <h2>{{ $t("Participation notifications") }}</h2>
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
        <o-checkbox
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
        </o-checkbox>
      </div>
      <div class="field">
        <o-checkbox
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
        </o-checkbox>
      </div>
      <div class="field">
        <o-checkbox
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
        </o-checkbox>
      </div>
    </section>
    <section class="my-4">
      <h2>{{ $t("Organizer notifications") }}</h2>
      <div class="field is-primary">
        <label
          class="has-text-weight-bold"
          for="notificationPendingParticipation"
          >{{
            $t("Notifications for manually approved participations to an event")
          }}</label
        >
        <p>
          {{
            $t(
              "If you have opted for manual validation of participants, Mobilizon will send you an email to inform you of new participations to be processed. You can choose the frequency of these notifications below."
            )
          }}
        </p>
        <o-select
          v-model="notificationPendingParticipation"
          id="notificationPendingParticipation"
          @input="updateSetting({ notificationPendingParticipation })"
        >
          <option
            v-for="(value, key) in notificationPendingParticipationValues"
            :value="key"
            :key="key"
          >
            {{ value }}
          </option>
        </o-select>
      </div>
    </section>
    <section class="my-4">
      <h2>{{ $t("Personal feeds") }}</h2>
      <p>
        {{
          $t(
            "These feeds contain event data for the events for which any of your profiles is a participant or creator. You should keep these private. You can find feeds for specific profiles on each profile edition page."
          )
        }}
      </p>
      <div v-if="feedTokens && feedTokens.length > 0">
        <div
          class="flex gap-2"
          v-for="feedToken in feedTokens"
          :key="feedToken.token"
        >
          <o-tooltip
            :label="$t('URL copied to clipboard')"
            :active="showCopiedTooltip.atom"
            always
            variant="success"
            position="left"
          >
            <o-button
              tag="a"
              icon-left="rss"
              @click="
                (e: Event) => copyURL(e, tokenToURL(feedToken.token, 'atom'), 'atom')
              "
              @keyup.enter="
                (e: Event) => copyURL(e, tokenToURL(feedToken.token, 'atom'), 'atom')
              "
              :href="tokenToURL(feedToken.token, 'atom')"
              target="_blank"
              >{{ $t("RSS/Atom Feed") }}</o-button
            >
          </o-tooltip>
          <o-tooltip
            :label="$t('URL copied to clipboard')"
            :active="showCopiedTooltip.ics"
            always
            variant="success"
            position="left"
          >
            <o-button
              tag="a"
              @click="
                (e: Event) => copyURL(e, tokenToURL(feedToken.token, 'ics'), 'ics')
              "
              @keyup.enter="
                (e: Event) => copyURL(e, tokenToURL(feedToken.token, 'ics'), 'ics')
              "
              icon-left="calendar-sync"
              :href="tokenToURL(feedToken.token, 'ics')"
              target="_blank"
              >{{ $t("ICS/WebCal Feed") }}</o-button
            >
          </o-tooltip>
          <o-button
            icon-left="refresh"
            variant="text"
            @click="openRegenerateFeedTokensConfirmation"
            @keyup.enter="openRegenerateFeedTokensConfirmation"
            >{{ $t("Regenerate new links") }}</o-button
          >
        </div>
      </div>
      <div v-else>
        <o-button
          icon-left="refresh"
          variant="text"
          @click="generateFeedTokens"
          @keyup.enter="generateFeedTokens"
          >{{ $t("Create new links") }}</o-button
        >
      </div>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { INotificationPendingEnum } from "@/types/enums";
import {
  SET_USER_SETTINGS,
  USER_NOTIFICATIONS,
  UPDATE_ACTIVITY_SETTING,
  USER_FRAGMENT_FEED_TOKENS,
} from "../../graphql/user";
import {
  IActivitySetting,
  IActivitySettingMethod,
  IUser,
} from "../../types/current-user.model";
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
import merge from "lodash/merge";
import { WEB_PUSH } from "@/graphql/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  computed,
  inject,
  onBeforeMount,
  onMounted,
  reactive,
  ref,
  watch,
} from "vue";
import { IConfig } from "@/types/config.model";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";
import { Dialog } from "@/plugins/dialog";

type NotificationSubType = { label: string; id: string };
type NotificationType = { label: string; subtypes: NotificationSubType[] };

const { result: loggedUserResult } = useQuery<{ loggedUser: IUser }>(
  USER_NOTIFICATIONS
);
const loggedUser = computed(() => loggedUserResult.value?.loggedUser);
const feedTokens = computed(() =>
  loggedUser.value?.feedTokens.filter(
    (token: IFeedToken) => token.actor === null
  )
);

const { result: webPushEnabledResult } = useQuery<{
  config: Pick<IConfig, "webPush">;
}>(WEB_PUSH);

const webPushEnabled = computed(
  () => webPushEnabledResult.value?.config?.webPush.enabled
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Notification settings")),
});

const notificationOnDay = ref<boolean | undefined>(true);
const notificationEachWeek = ref<boolean | undefined>(false);
const notificationBeforeEvent = ref<boolean | undefined>(false);
const notificationPendingParticipation = ref<
  INotificationPendingEnum | undefined
>(INotificationPendingEnum.NONE);
const groupNotifications = ref<INotificationPendingEnum | undefined>(
  INotificationPendingEnum.ONE_DAY
);
const notificationPendingParticipationValues = ref<Record<string, unknown>>({});
const groupNotificationsValues = ref<Record<string, unknown>>({});
const showCopiedTooltip = reactive({ ics: false, atom: false });
const subscribed = ref(false);
const canShowWebPush = ref(false);

const notificationMethods = {
  email: t("Email"),
  push: t("Push"),
};

const defaultNotificationValues = {
  participation_event_updated: {
    email: { enabled: true, disabled: true },
    push: { enabled: true, disabled: true },
  },
  participation_event_comment: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  event_new_pending_participation: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  event_new_participation: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  event_created: {
    email: { enabled: true, disabled: false },
    push: { enabled: false, disabled: false },
  },
  event_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  discussion_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  post_published: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  post_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  resource_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  member_request: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  member_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  user_email_password_updated: {
    email: { enabled: true, disabled: true },
    push: { enabled: false, disabled: true },
  },
  event_comment_mention: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  discussion_mention: {
    email: { enabled: true, disabled: false },
    push: { enabled: false, disabled: false },
  },
  event_new_comment: {
    email: { enabled: true, disabled: false },
    push: { enabled: false, disabled: false },
  },
};

const notificationTypes: NotificationType[] = [
  {
    label: t("Mentions") as string,
    subtypes: [
      {
        id: "event_comment_mention",
        label: t("I've been mentionned in a comment under an event") as string,
      },
      {
        id: "discussion_mention",
        label: t("I've been mentionned in a group discussion") as string,
      },
    ],
  },
  {
    label: t("Participations") as string,
    subtypes: [
      {
        id: "participation_event_updated",
        label: t("An event I'm going to has been updated") as string,
      },
      {
        id: "participation_event_comment",
        label: t("An event I'm going to has posted an announcement") as string,
      },
    ],
  },
  {
    label: t("Organizers") as string,
    subtypes: [
      {
        id: "event_new_pending_participation",
        label: t(
          "An event I'm organizing has a new pending participation"
        ) as string,
      },
      {
        id: "event_new_participation",
        label: t("An event I'm organizing has a new participation") as string,
      },
      {
        id: "event_new_comment",
        label: t("An event I'm organizing has a new comment") as string,
      },
    ],
  },
  {
    label: t("Group activity") as string,
    subtypes: [
      {
        id: "event_created",
        label: t("An event from one of my groups has been published") as string,
      },
      {
        id: "event_updated",
        label: t(
          "An event from one of my groups has been updated or deleted"
        ) as string,
      },
      {
        id: "discussion_updated",
        label: t("A discussion has been created or updated") as string,
      },
      {
        id: "post_published",
        label: t("A post has been published") as string,
      },
      {
        id: "post_updated",
        label: t("A post has been updated") as string,
      },
      {
        id: "resource_updated",
        label: t("A resource has been created or updated") as string,
      },
      {
        id: "member_request",
        label: t("A member requested to join one of my groups") as string,
      },
      {
        id: "member_updated",
        label: t("A member has been updated") as string,
      },
    ],
  },
  {
    label: t("User settings") as string,
    subtypes: [
      {
        id: "user_email_password_updated",
        label: t("You changed your email or password") as string,
      },
    ],
  },
];

const userNotificationValues = computed(
  (): Record<
    string,
    Record<IActivitySettingMethod, { enabled: boolean; disabled: boolean }>
  > => {
    return (loggedUser.value?.activitySettings ?? []).reduce(
      (acc, activitySetting) => {
        acc[activitySetting.key] = acc[activitySetting.key] || {};
        acc[activitySetting.key][activitySetting.method] =
          acc[activitySetting.key][activitySetting.method] || {};
        acc[activitySetting.key][activitySetting.method].enabled =
          activitySetting.enabled;
        return acc;
      },
      {} as Record<
        string,
        Record<IActivitySettingMethod, { enabled: boolean; disabled: boolean }>
      >
    );
  }
);

const notificationValues = computed(
  (): Record<
    string,
    Record<IActivitySettingMethod, { enabled: boolean; disabled: boolean }>
  > => {
    const values = merge(
      defaultNotificationValues,
      userNotificationValues.value
    );
    for (const value in values) {
      if (!canShowWebPush.value) {
        values[value].push.disabled = true;
      }
    }
    return values;
  }
);

onMounted(async () => {
  notificationPendingParticipationValues.value = {
    [INotificationPendingEnum.NONE]: t("Do not receive any mail"),
    [INotificationPendingEnum.DIRECT]: t("Receive one email per request"),
    [INotificationPendingEnum.ONE_HOUR]: t("Hourly email summary"),
    [INotificationPendingEnum.ONE_DAY]: t("Daily email summary"),
    [INotificationPendingEnum.ONE_WEEK]: t("Weekly email summary"),
  };
  groupNotificationsValues.value = {
    [INotificationPendingEnum.NONE]: t("Do not receive any mail"),
    [INotificationPendingEnum.DIRECT]: t("Receive one email for each activity"),
    [INotificationPendingEnum.ONE_HOUR]: t("Hourly email summary"),
    [INotificationPendingEnum.ONE_DAY]: t("Daily email summary"),
    [INotificationPendingEnum.ONE_WEEK]: t("Weekly email summary"),
  };
  canShowWebPush.value = await checkCanShowWebPush();
});

watch(loggedUser, () => {
  if (loggedUser.value?.settings) {
    notificationOnDay.value = loggedUser.value.settings.notificationOnDay;
    notificationEachWeek.value = loggedUser.value.settings.notificationEachWeek;
    notificationBeforeEvent.value =
      loggedUser.value.settings.notificationBeforeEvent;
    notificationPendingParticipation.value =
      loggedUser.value.settings.notificationPendingParticipation;
    groupNotifications.value = loggedUser.value.settings.groupNotifications;
  }
});

const { mutate: updateSetting } = useMutation<{ setUserSettings: string }>(
  SET_USER_SETTINGS,
  () => ({ refetchQueries: [{ query: USER_NOTIFICATIONS }] })
);

const tokenToURL = (token: string, format: string): string => {
  return `${window.location.origin}/events/going/${token}/${format}`;
};

const copyURL = (e: Event, url: string, format: "ics" | "atom"): void => {
  if (navigator.clipboard) {
    e.preventDefault();
    navigator.clipboard.writeText(url);
    showCopiedTooltip[format] = true;
    setTimeout(() => {
      showCopiedTooltip[format] = false;
    }, 2000);
  }
};

const dialog = inject<Dialog>("dialog");

const openRegenerateFeedTokensConfirmation = () => {
  dialog?.confirm({
    variant: "warning",
    title: t("Regenerate new links") as string,
    message: t(
      "You'll need to change the URLs where there were previously entered."
    ) as string,
    confirmText: t("Regenerate new links") as string,
    cancelText: t("Cancel") as string,
    onConfirm: () => regenerateFeedTokens(),
  });
};

const regenerateFeedTokens = async (): Promise<void> => {
  if (!feedTokens.value || feedTokens.value?.length < 1) return;
  await deleteFeedToken({ token: feedTokens.value[0].token });
  await createNewFeedToken(
    {},
    {
      update(cache, { data }) {
        const userId = data?.createFeedToken.user?.id;
        const newFeedToken = data?.createFeedToken.token;

        if (!newFeedToken) return;

        let cachedData = cache.readFragment<{
          id: string | undefined;
          feedTokens: { token: string }[];
        }>({
          id: `User:${userId}`,
          fragment: USER_FRAGMENT_FEED_TOKENS,
        });
        // Remove the old token
        cachedData = {
          id: cachedData?.id,
          feedTokens: [
            ...(cachedData?.feedTokens ?? []).slice(0, -1),
            { token: newFeedToken },
          ],
        };
        cache.writeFragment({
          id: `User:${userId}`,
          fragment: USER_FRAGMENT_FEED_TOKENS,
          data: cachedData,
        });
      },
    }
  );
};

const generateFeedTokens = async (): Promise<void> => {
  await createNewFeedToken();
};

const {
  mutate: registerPushMutation,
  onDone: registerPushMutationDone,
  onError: registerPushMutationError,
} = useMutation(REGISTER_PUSH_MUTATION);

registerPushMutationDone(() => {
  subscribed.value = true;
});

registerPushMutationError((err) => {
  console.error(err);
});

const subscribeToWebPush = async (): Promise<void> => {
  if (canShowWebPush.value) {
    const subscription = await subscribeUserToPush();
    if (subscription) {
      const subscriptionJSON = subscription?.toJSON();
      registerPushMutation({
        endpoint: subscriptionJSON.endpoint,
        auth: subscriptionJSON?.keys?.auth,
        p256dh: subscriptionJSON?.keys?.p256dh,
      });
      subscribed.value = true;
    } else {
      // tnotifier.error(
      //   t("Error while subscribing to push notifications") as string
      // );
    }
  } else {
    console.error("can't do webpush");
  }
};

const {
  mutate: unregisterPushMutation,
  onDone: onUnregisterPushMutationDone,
  onError: onUnregisterPushMutationError,
} = useMutation(UNREGISTER_PUSH_MUTATION);

onUnregisterPushMutationDone(({ data }) => {
  console.debug(data);
  subscribed.value = false;
});

onUnregisterPushMutationError((e) => {
  console.error(e);
});

const unsubscribeToWebPush = async (): Promise<void> => {
  const endpoint = await unsubscribeUserToPush();
  if (endpoint) {
    unregisterPushMutation({
      endpoint,
    });
  }
};

const checkCanShowWebPush = async (): Promise<boolean> => {
  try {
    if (!window.isSecureContext || !("serviceWorker" in navigator))
      return Promise.resolve(false);
    const registration = await navigator.serviceWorker.getRegistration();
    return registration !== undefined;
  } catch (e) {
    console.error(e);
    return Promise.resolve(false);
  }
};

onBeforeMount(async () => {
  subscribed.value = await isSubscribed();
});

const { mutate: updateNotificationValue } = useMutation<
  {
    updateActivitySetting: IActivitySetting;
  },
  {
    key: string;
    method: IActivitySettingMethod;
    enabled: boolean;
  }
>(UPDATE_ACTIVITY_SETTING);

const isSubscribed = async (): Promise<boolean> => {
  try {
    if (!("serviceWorker" in navigator)) return Promise.resolve(false);
    const registration = await navigator.serviceWorker.getRegistration();
    return (await registration?.pushManager?.getSubscription()) != null;
  } catch (e) {
    console.error(e);
    return Promise.resolve(false);
  }
};

const { mutate: deleteFeedToken } = useMutation(DELETE_FEED_TOKEN);

const { mutate: createNewFeedToken } = useMutation(CREATE_FEED_TOKEN, () => ({
  update(cache, { data }) {
    const userId = data?.createFeedToken.user?.id;
    const newFeedToken = data?.createFeedToken.token;

    if (!newFeedToken) return;

    let cachedData = cache.readFragment<{
      id: string | undefined;
      feedTokens: { token: string }[];
    }>({
      id: `User:${userId}`,
      fragment: USER_FRAGMENT_FEED_TOKENS,
    });
    // Add the new token to the list
    cachedData = {
      id: cachedData?.id,
      feedTokens: [...(cachedData?.feedTokens ?? []), { token: newFeedToken }],
    };
    cache.writeFragment({
      id: `User:${userId}`,
      fragment: USER_FRAGMENT_FEED_TOKENS,
      data: cachedData,
    });
  },
}));
</script>

<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.field {
  &:not(:last-child) {
    margin-bottom: 1.5rem;
  }

  a.change-timezone {
    text-decoration: underline;
    text-decoration-thickness: 2px;
    @include margin-left(5px);
  }
}

:deep(.buttons > *:not(:last-child) .button) {
  margin-right: 0.5rem;
  @include margin-right(0.5rem);
}
</style>
