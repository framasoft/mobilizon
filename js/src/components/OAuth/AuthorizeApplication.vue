<template>
  <h1 class="text-3xl">
    {{ t("Autorize this application to access your account?") }}
  </h1>

  <div
    class="rounded-lg bg-mbz-warning dark:text-black shadow-xl my-6 p-4 flex items-center gap-2"
  >
    <AlertCircle :size="42" />
    <p>
      {{
        t(
          "This application will be able to access all of your informations and post content on your behalf. Make sure you only approve applications you trust."
        )
      }}
    </p>
  </div>

  <div class="rounded-lg bg-white dark:bg-zinc-900 shadow-xl my-6">
    <div class="p-4 pb-0">
      <p class="text-3xl font-bold">{{ authApplication.name }}</p>
      <p>{{ authApplication.website }}</p>
    </div>
    <div class="flex gap-3 p-4">
      <o-button @click="() => authorize()">{{ t("Authorize") }}</o-button>
      <o-button outlined tag="router-link" :to="{ name: RouteName.HOME }">{{
        t("Decline")
      }}</o-button>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useHead } from "@vueuse/head";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";
import { AUTORIZE_APPLICATION } from "@/graphql/application";
import AlertCircle from "vue-material-design-icons/AlertCircle.vue";
import RouteName from "@/router/name";
import { IApplication } from "@/types/application.model";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  authApplication: IApplication;
  redirectURI?: string | null;
  state?: string | null;
  scope?: string | null;
}>();

const { mutate: authorizeMutation, onDone: onAuthorizeMutationDone } =
  useMutation<
    { authorizeApplication: { code: string; state: string } },
    {
      applicationClientId: string;
      redirectURI: string;
      state?: string | null;
      scope?: string | null;
    }
  >(AUTORIZE_APPLICATION);

const authorize = () => {
  authorizeMutation({
    applicationClientId: props.authApplication.clientId,
    redirectURI: props.redirectURI as string,
    state: props.state,
    scope: props.scope,
  });
};

onAuthorizeMutationDone(({ data }) => {
  const code = data?.authorizeApplication?.code;
  const returnedState = data?.authorizeApplication?.state ?? "";

  if (!code) return;

  if (props.redirectURI) {
    const params = new URLSearchParams(
      Object.entries({ code, state: returnedState })
    );
    window.location.assign(
      new URL(`${props.redirectURI}?${params.toString()}`)
    );
  }
});

useHead({
  title: computed(() => t("Authorize application")),
});
</script>
