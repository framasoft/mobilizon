<template>
  <section class="container mx-auto hero is-fullheight">
    <div class="hero-body">
      <div class="container mx-auto">
        <div class="columns is-vcentered">
          <div class="column has-text-centered">
            <o-button
              variant="primary"
              size="is-medium"
              tag="router-link"
              :to="{
                name: RouteName.LOGIN,
                query: {
                  code: LoginErrorCode.NEED_TO_LOGIN,
                  redirect: pathAfterLogin,
                },
              }"
              >{{ $t("Login on {instance}", { instance: host }) }}</o-button
            >
          </div>
          <vertical-divider :content="$t('Or')" />
          <div class="column">
            <h2 class="text-2xl">
              {{ $t("I have an account on another Mobilizon instance.") }}
            </h2>
            <p>{{ $t("Other software may also support this.") }}</p>
            <p>{{ sentence }}</p>
            <form @submit.prevent="redirectToInstance">
              <o-field :label="$t('Your federated identity')">
                <o-field>
                  <o-input
                    expanded
                    autocapitalize="none"
                    autocorrect="off"
                    v-model="remoteActorAddress"
                    :placeholder="$t('profile@instance')"
                  ></o-input>
                  <p class="control">
                    <button class="button is-primary" type="submit">
                      {{ $t("Go") }}
                    </button>
                  </p>
                </o-field>
              </o-field>
            </form>
          </div>
        </div>
        <div class="has-text-centered">
          <o-button tag="a" type="is-text" @click="$router.go(-1)">{{
            $t("Back to previous page")
          }}</o-button>
        </div>
      </div>
    </div>
  </section>
</template>
<script lang="ts" setup>
import VerticalDivider from "@/components/Utils/VerticalDivider.vue";
import { LoginErrorCode } from "@/types/enums";
import RouteName from "../../router/name";
import { computed, ref } from "vue";

defineProps<{
  uri: string;
  pathAfterLogin?: string;
  sentence?: string;
}>();

const remoteActorAddress = ref("");

// eslint-disable-next-line class-methods-use-this
const host = computed((): string => {
  return window.location.hostname;
});

const redirectToInstance = async (): Promise<void> => {
  const [, host] = remoteActorAddress.value.split("@", 2);
  const remoteInteractionURI = await webFingerFetch(
    host,
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
      return link.template.replace("{uri}", encodeURIComponent(this.uri));
    }
  }
  throw new Error("No interaction path found in webfinger data");
};
</script>
