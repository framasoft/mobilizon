<template>
  <section class="container mx-auto max-w-2xl">
    <div class="flex flex-wrap gap-4 items-center w-full">
      <div class="px-2 flex-1">
        <h2 class="text-2xl">
          {{
            t("I have an account on {instance}.", { instance: instanceName })
          }}
        </h2>
        <i18n-t keypath="My federated identity ends in {domain}">
          <template #domain>
            <code>@{{ host }}</code>
          </template>
        </i18n-t>
        <o-button
          variant="primary"
          size="medium"
          tag="router-link"
          class="mt-4"
          :to="{
            name: RouteName.LOGIN,
            query: {
              code: LoginErrorCode.NEED_TO_LOGIN,
              redirect: pathAfterLogin,
            },
          }"
          >{{ t("Login on {instance}", { instance: host }) }}</o-button
        >
      </div>
      <div class="sm:border-l-4 px-2 sm:px-4 flex-1">
        <h2 class="text-2xl">
          {{ t("I have an account on another Mobilizon instance.") }}
        </h2>
        <p>{{ t("Other software may also support this.") }}</p>
        <p>{{ sentence }}</p>
        <form @submit.prevent="redirectToInstance">
          <o-field
            :label="t('Your federated identity')"
            label-for="remoteProfileInput"
          >
            <o-field>
              <o-input
                id="remoteProfileInput"
                expanded
                autocapitalize="none"
                autocorrect="off"
                v-model="remoteActorAddress"
                :placeholder="t('profile{\'@\'}instance')"
              ></o-input>
              <p class="control">
                <o-button type="submit">
                  {{ t("Go") }}
                </o-button>
              </p>
            </o-field>
          </o-field>
        </form>
      </div>
    </div>
    <div class="text-center">
      <o-button tag="a" variant="text" @click="$router.go(-1)">{{
        t("Back to previous page")
      }}</o-button>
    </div>
  </section>
</template>
<script lang="ts" setup>
import { LoginErrorCode } from "@/types/enums";
import RouteName from "../../router/name";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useInstanceName } from "@/composition/apollo/config";

const props = defineProps<{
  uri: string;
  pathAfterLogin?: string;
  sentence?: string;
}>();

const remoteActorAddress = ref("");

const { t } = useI18n({ useScope: "global" });

const { instanceName } = useInstanceName();

const host = computed((): string => {
  return window.location.hostname;
});

const redirectToInstance = async (): Promise<void> => {
  const [, hostname] = remoteActorAddress.value.split("@", 2);
  const remoteInteractionURI = await webFingerFetch(
    hostname,
    remoteActorAddress.value
  );
  window.open(remoteInteractionURI);
};

const webFingerFetch = async (
  hostname: string,
  identity: string
): Promise<string> => {
  const scheme = process.env.NODE_ENV === "production" ? "https" : "http";
  const data = await (
    await fetch(
      `${scheme}://${hostname}/.well-known/webfinger?resource=acct:${identity}`
    )
  ).json();
  if (data && Array.isArray(data.links)) {
    const link: { template: string } = data.links.find(
      (someLink: any) =>
        someLink &&
        typeof someLink.template === "string" &&
        someLink.rel === "http://ostatus.org/schema/1.0/subscribe"
    );

    if (link && link.template.includes("{uri}")) {
      return link.template.replace("{uri}", encodeURIComponent(props.uri));
    }
  }
  throw new Error("No interaction path found in webfinger data");
};
</script>
