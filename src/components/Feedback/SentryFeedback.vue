<template>
  <form
    v-if="sentryReady && !submittedFeedback"
    @submit.prevent="sendErrorToSentry"
  >
    <o-field :label="t('What happened?')" label-for="what-happened">
      <o-input
        v-model="feedback"
        type="textarea"
        id="what-happened"
        :placeholder="t(`I've clicked on X, then on Y`)"
      />
    </o-field>
    <o-button icon-left="send" native-type="submit" variant="primary">{{
      t("Send feedback")
    }}</o-button>
    <p class="prose dark:prose-invert">
      {{
        t(
          "Please add as many details as possible to help identify the problem."
        )
      }}
    </p>
  </form>
  <o-notification variant="danger" v-else-if="feedbackError">
    <p>
      {{
        t(
          "Sorry, we wen't able to save your feedback. Don't worry, we'll try to fix this issue anyway."
        )
      }}
    </p>
    <i18n-t keypath="You may now close this page or {return_to_the_homepage}.">
      <template #return_to_the_homepage>
        <router-link :to="{ name: RouteName.HOME }">{{
          t("return to the homepage")
        }}</router-link>
      </template>
    </i18n-t>
  </o-notification>
  <o-notification variant="success" v-else-if="submittedFeedback">
    <p>{{ t("Thanks a lot, your feedback was submitted!") }}</p>
    <i18n-t keypath="You may now close this page or {return_to_the_homepage}.">
      <template #return_to_the_homepage>
        <router-link :to="{ name: RouteName.HOME }">{{
          t("return to the homepage")
        }}</router-link>
      </template>
    </i18n-t>
  </o-notification>
  <div class="prose dark:prose-invert" v-if="!sentryReady || submittedFeedback">
    <p v-if="submittedFeedback">{{ $t("You may also:") }}</p>
    <ul>
      <li>
        <a href="https://framacolibri.org/c/mobilizon/39" target="_blank">{{
          $t("Open a topic on our forum")
        }}</a>
      </li>
      <li>
        <a
          href="https://framagit.org/framasoft/mobilizon/-/issues/"
          target="_blank"
          >{{ $t("Open an issue on our bug tracker (advanced users)") }}</a
        >
      </li>
    </ul>
  </div>
</template>
<script lang="ts" setup>
import { convertConfig } from "@/services/statistics";
import { IAnalyticsConfig } from "@/types/config.model";
import { ISentryConfiguration } from "@/types/analytics/sentry.model";
import { submitFeedback } from "@/services/statistics/sentry";
import { computed, ref } from "vue";
import { useLoggedUser } from "@/composition/apollo/user";
import { useI18n } from "vue-i18n";
import RouteName from "@/router/name";

const props = defineProps<{
  providerConfig: IAnalyticsConfig;
}>();

const { t } = useI18n({ useScope: "global" });

const { loggedUser } = useLoggedUser();

const feedback = ref("");
const submittedFeedback = ref(false);
const feedbackError = ref(false);

const sentryConfig = computed((): ISentryConfiguration | undefined => {
  if (props.providerConfig?.configuration) {
    return convertConfig(
      props.providerConfig?.configuration
    ) as ISentryConfiguration;
  }
  return undefined;
});

const sentryReady = computed(() => {
  const eventId = window.sessionStorage.getItem("lastEventId");
  const dsn = sentryConfig.value?.dsn;
  const organization = sentryConfig.value?.organization;
  const project = sentryConfig.value?.project;
  const host = sentryConfig.value?.host;
  return eventId && dsn && organization && project && host;
});

const sendErrorToSentry = async () => {
  try {
    const eventId = window.sessionStorage.getItem("lastEventId");
    const dsn = sentryConfig.value?.dsn;
    const organization = sentryConfig.value?.organization;
    const project = sentryConfig.value?.project;
    const host = sentryConfig.value?.host;
    const endpoint = `https://${host}/api/0/projects/${organization}/${project}/user-feedback/`;
    if (eventId && dsn && sentryReady) {
      await submitFeedback(endpoint, dsn, {
        event_id: eventId,
        name:
          loggedUser.value?.defaultActor?.preferredUsername || "Unknown user",
        email: loggedUser.value?.email || "unknown@email.org",
        comments: feedback.value,
      });
      submittedFeedback.value = true;
    }
  } catch (error) {
    console.error(error);
    feedbackError.value = true;
  }
};
</script>
