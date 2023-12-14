<template>
  <div class="container mx-auto" id="error-wrapper">
    <div class="">
      <section>
        <div class="text-center">
          <picture>
            <source
              :srcset="`/img/pics/error-480w.webp  1x, /img/pics/error-1024w.webp 2x`"
              type="image/webp"
            />
            <img
              :src="`/img/pics/error-480w.webp`"
              alt=""
              width="480"
              height="312"
              loading="lazy"
            />
          </picture>
        </div>
        <o-notification variant="danger" class="">
          <h1>
            {{
              t(
                "An error has occured. Sorry about that. You may try to reload the page."
              )
            }}
          </h1>
        </o-notification>
      </section>
      <o-loading v-if="loading" v-model:active="loading" />
      <section v-else>
        <h2 class="">{{ t("What can I do to help?") }}</h2>
        <p class="prose dark:prose-invert">
          <i18n-t
            tag="span"
            keypath="{instanceName} is an instance of {mobilizon_link}, a free software built with the community."
          >
            <template #instanceName>
              <b>{{ instanceName }}</b>
            </template>
            <template #mobilizon_link>
              <a href="https://joinmobilizon.org">{{ t("Mobilizon") }}</a>
            </template>
          </i18n-t>
          <span v-if="sentryEnabled">
            {{
              t(
                "We collect your feedback and the error information in order to improve this service."
              )
            }}</span
          >
          <span v-else>
            {{
              t(
                "We improve this software thanks to your feedback. To let us know about this issue, two possibilities (both unfortunately require user account creation):"
              )
            }}
          </span>
        </p>
        <SentryFeedback
          v-if="sentryProvider"
          :providerConfig="sentryProvider"
        />

        <p class="prose dark:prose-invert" v-if="!sentryEnabled">
          {{
            t(
              "Please add as many details as possible to help identify the problem."
            )
          }}
        </p>

        <details>
          <summary>{{ t("Technical details") }}</summary>
          <p>{{ t("Error message") }}</p>
          <pre>{{ error }}</pre>
          <p>{{ t("Error stacktrace") }}</p>
          <pre>{{ error.stack }}</pre>
        </details>
        <p v-if="!sentryEnabled">
          {{
            t(
              "The technical details of the error can help developers solve the problem more easily. Please add them to your feedback."
            )
          }}
        </p>
        <div class="buttons" v-if="!sentryEnabled">
          <o-tooltip
            :label="tooltipConfig.label"
            :variant="tooltipConfig.variant"
            :active="copied !== false"
            always
          >
            <o-button
              @click="copyErrorToClipboard"
              @keyup.enter="copyErrorToClipboard"
              >{{ t("Copy details to clipboard") }}</o-button
            >
          </o-tooltip>
        </div>
      </section>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { checkProviderConfig } from "@/services/statistics";
import { IAnalyticsConfig, IConfig } from "@/types/config.model";
import { computed, defineAsyncComponent, ref } from "vue";
import { useQuery, useQueryLoading } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";
import { useAnalytics } from "@/composition/apollo/config";
import { INSTANCE_NAME } from "@/graphql/config";
const SentryFeedback = defineAsyncComponent(
  () => import("./Feedback/SentryFeedback.vue")
);

const { analytics } = useAnalytics();

const loading = useQueryLoading();

const props = defineProps<{
  error: Error;
}>();

const copied = ref<"success" | "error" | false>(false);

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Error")),
});

const { result: instanceConfig } = useQuery<{ config: Pick<IConfig, "name"> }>(
  INSTANCE_NAME
);

const instanceName = computed(() => instanceConfig.value?.config.name);

const copyErrorToClipboard = async (): Promise<void> => {
  try {
    if (window.isSecureContext && navigator.clipboard) {
      await navigator.clipboard.writeText(fullErrorString.value);
    } else {
      fallbackCopyTextToClipboard(fullErrorString.value);
    }
    copied.value = "success";
    setTimeout(() => {
      copied.value = false;
    }, 2000);
  } catch (e) {
    copied.value = "error";
    console.error("Unable to copy to clipboard");
    console.error(e);
  }
};

const fullErrorString = computed((): string => {
  return `${props.error.name}: ${props.error.message}\n\n${props.error.stack}`;
});

const tooltipConfig = computed(
  (): { label: string | null; variant: string | null } => {
    if (copied.value === "success")
      return {
        label: t("Error details copied!") as string,
        variant: "success",
      };
    if (copied.value === "error")
      return {
        label: t("Unable to copy to clipboard") as string,
        variant: "danger",
      };
    return { label: null, variant: "primary" };
  }
);

const fallbackCopyTextToClipboard = (text: string): void => {
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
};

const sentryEnabled = computed((): boolean => {
  return sentryProvider.value?.enabled === true;
});

const sentryProvider = computed((): IAnalyticsConfig | undefined => {
  return checkProviderConfig(analytics.value ?? [], "sentry");
});
</script>
<style lang="scss" scoped>
#error-wrapper {
  width: 100%;

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
