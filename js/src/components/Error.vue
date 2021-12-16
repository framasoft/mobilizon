<template>
  <div class="container section" id="error-wrapper">
    <div class="column">
      <section>
        <div class="picture-wrapper">
          <picture>
            <source
              srcset="
                /img/pics/error-480w.webp  1x,
                /img/pics/error-1024w.webp 2x
              "
              type="image/webp"
            />
            <source
              srcset="/img/pics/error-480w.jpg 1x, /img/pics/error-1024w.jpg 2x"
              type="image/jpeg"
            />

            <img
              :src="`/img/pics/error-480w.jpg`"
              alt=""
              width="480"
              height="312"
              loading="lazy"
            />
          </picture>
        </div>
        <b-message type="is-danger" class="is-size-5">
          <h1>
            {{
              $t(
                "An error has occured. Sorry about that. You may try to reload the page."
              )
            }}
          </h1>
        </b-message>
      </section>
      <b-loading v-if="$apollo.loading" :active.sync="$apollo.loading" />
      <section v-else>
        <h2 class="is-size-5">{{ $t("What can I do to help?") }}</h2>
        <p class="content">
          <i18n
            tag="span"
            path="{instanceName} is an instance of {mobilizon_link}, a free software built with the community."
          >
            <b slot="instanceName">{{ config.name }}</b>
            <a slot="mobilizon_link" href="https://joinmobilizon.org">{{
              $t("Mobilizon")
            }}</a>
          </i18n>
          <span v-if="sentryEnabled && sentryReady">
            {{
              $t(
                "We collect your feedback and the error information in order to improve this service."
              )
            }}</span
          >
          <span v-else>
            {{
              $t(
                "We improve this software thanks to your feedback. To let us know about this issue, two possibilities (both unfortunately require user account creation):"
              )
            }}
          </span>
        </p>
        <form
          v-if="sentryEnabled && sentryReady && !submittedFeedback"
          @submit.prevent="sendErrorToSentry"
        >
          <b-field :label="$t('What happened?')" label-for="what-happened">
            <b-input
              v-model="feedback"
              type="textarea"
              id="what-happened"
              :placeholder="$t(`I've clicked on X, then on Y`)"
            />
          </b-field>
          <b-button icon-left="send" native-type="submit" type="is-primary">{{
            $t("Send feedback")
          }}</b-button>
          <p class="content">
            {{
              $t(
                "Please add as many details as possible to help identify the problem."
              )
            }}
          </p>
        </form>
        <b-message type="is-danger" v-else-if="feedbackError">
          <p>
            {{
              $t(
                "Sorry, we wen't able to save your feedback. Don't worry, we'll try to fix this issue anyway."
              )
            }}
          </p>
          <i18n path="You may now close this page or {return_to_the_homepage}.">
            <template #return_to_the_homepage>
              <router-link :to="{ name: RouteName.HOME }">{{
                $t("return to the homepage")
              }}</router-link>
            </template>
          </i18n>
        </b-message>
        <b-message type="is-success" v-else-if="submittedFeedback">
          <p>{{ $t("Thanks a lot, your feedback was submitted!") }}</p>
          <i18n path="You may now close this page or {return_to_the_homepage}.">
            <template #return_to_the_homepage>
              <router-link :to="{ name: RouteName.HOME }">{{
                $t("return to the homepage")
              }}</router-link>
            </template>
          </i18n>
        </b-message>
        <div
          class="content"
          v-if="!(sentryEnabled && sentryReady) || submittedFeedback"
        >
          <p v-if="submittedFeedback">{{ $t("You may also:") }}</p>
          <ul>
            <li>
              <a
                href="https://framacolibri.org/c/mobilizon/39"
                target="_blank"
                >{{ $t("Open a topic on our forum") }}</a
              >
            </li>
            <li>
              <a
                href="https://framagit.org/framasoft/mobilizon/-/issues/"
                target="_blank"
                >{{
                  $t("Open an issue on our bug tracker (advanced users)")
                }}</a
              >
            </li>
          </ul>
        </div>
        <p class="content" v-if="!sentryEnabled">
          {{
            $t(
              "Please add as many details as possible to help identify the problem."
            )
          }}
        </p>

        <details>
          <summary class="is-size-5">{{ $t("Technical details") }}</summary>
          <p>{{ $t("Error message") }}</p>
          <pre>{{ error }}</pre>
          <p>{{ $t("Error stacktrace") }}</p>
          <pre>{{ error.stack }}</pre>
        </details>
        <p v-if="!sentryEnabled">
          {{
            $t(
              "The technical details of the error can help developers solve the problem more easily. Please add them to your feedback."
            )
          }}
        </p>
        <div class="buttons" v-if="!sentryEnabled">
          <b-tooltip
            :label="tooltipConfig.label"
            :type="tooltipConfig.type"
            :active="copied !== false"
            always
          >
            <b-button
              @click="copyErrorToClipboard"
              @keyup.enter="copyErrorToClipboard"
              >{{ $t("Copy details to clipboard") }}</b-button
            >
          </b-tooltip>
        </div>
      </section>
    </div>
  </div>
</template>
<script lang="ts">
import { CONFIG } from "@/graphql/config";
import { checkProviderConfig, convertConfig } from "@/services/statistics";
import { IAnalyticsConfig, IConfig } from "@/types/config.model";
import { Component, Prop, Vue } from "vue-property-decorator";
import { LOGGED_USER } from "@/graphql/user";
import { IUser } from "@/types/current-user.model";
import { ISentryConfiguration } from "@/types/analytics/sentry.model";
import { submitFeedback } from "@/services/statistics/sentry";
import RouteName from "@/router/name";

@Component({
  apollo: {
    config: CONFIG,
    loggedUser: LOGGED_USER,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.$t("Error") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class ErrorComponent extends Vue {
  @Prop({ required: true, type: Error }) error!: Error;

  copied: "success" | "error" | false = false;

  config!: IConfig;

  feedback = "";

  submittedFeedback = false;

  feedbackError = false;

  loggedUser!: IUser;

  RouteName = RouteName;

  async copyErrorToClipboard(): Promise<void> {
    try {
      if (window.isSecureContext && navigator.clipboard) {
        await navigator.clipboard.writeText(this.fullErrorString);
      } else {
        this.fallbackCopyTextToClipboard(this.fullErrorString);
      }
      this.copied = "success";
      setTimeout(() => {
        this.copied = false;
      }, 2000);
    } catch (e) {
      this.copied = "error";
      console.error("Unable to copy to clipboard");
      console.error(e);
    }
  }

  get fullErrorString(): string {
    return `${this.error.name}: ${this.error.message}\n\n${this.error.stack}`;
  }

  get tooltipConfig(): { label: string | null; type: string | null } {
    if (this.copied === "success")
      return {
        label: this.$t("Error details copied!") as string,
        type: "is-success",
      };
    if (this.copied === "error")
      return {
        label: this.$t("Unable to copy to clipboard") as string,
        type: "is-danger",
      };
    return { label: null, type: "is-primary" };
  }

  private fallbackCopyTextToClipboard(text: string): void {
    const textArea = document.createElement("textarea");
    textArea.value = text;

    // Avoid scrolling to bottom
    textArea.style.top = "0";
    textArea.style.left = "0";
    textArea.style.position = "fixed";

    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    document.execCommand("copy");

    document.body.removeChild(textArea);
  }

  get sentryEnabled(): boolean {
    return this.sentryProvider?.enabled === true;
  }

  get sentryProvider(): IAnalyticsConfig | undefined {
    return this.config && checkProviderConfig(this.config, "sentry");
  }

  get sentryConfig(): ISentryConfiguration | undefined {
    if (this.sentryProvider?.configuration) {
      return convertConfig(
        this.sentryProvider?.configuration
      ) as ISentryConfiguration;
    }
    return undefined;
  }

  get sentryReady() {
    const eventId = window.sessionStorage.getItem("lastEventId");
    const dsn = this.sentryConfig?.dsn;
    const organization = this.sentryConfig?.organization;
    const project = this.sentryConfig?.project;
    const host = this.sentryConfig?.host;
    return eventId && dsn && organization && project && host;
  }

  async sendErrorToSentry() {
    try {
      const eventId = window.sessionStorage.getItem("lastEventId");
      const dsn = this.sentryConfig?.dsn;
      const organization = this.sentryConfig?.organization;
      const project = this.sentryConfig?.project;
      const host = this.sentryConfig?.host;
      const endpoint = `https://${host}/api/0/projects/${organization}/${project}/user-feedback/`;
      if (eventId && dsn && this.sentryReady) {
        await submitFeedback(endpoint, dsn, {
          event_id: eventId,
          name:
            this.loggedUser?.defaultActor?.preferredUsername || "Unknown user",
          email: this.loggedUser?.email || "unknown@email.org",
          comments: this.feedback,
        });
        this.submittedFeedback = true;
      }
    } catch (error) {
      console.error(error);
      this.feedbackError = true;
    }
  }
}
</script>
<style lang="scss" scoped>
#error-wrapper {
  width: 100%;
  background: $white;

  section {
    margin-bottom: 2rem;
  }

  .picture-wrapper {
    text-align: center;
  }

  details {
    summary:hover {
      cursor: pointer;
    }
  }
}
</style>
