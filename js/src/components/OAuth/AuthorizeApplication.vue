<template>
  <div>
    <h1 class="text-3xl">
      {{ t("Autorize this application to access your account?") }}
    </h1>

    <div class="rounded-lg bg-white dark:bg-zinc-900 shadow-xl my-6">
      <div class="p-4 pb-0">
        <p class="text-3xl font-bold">{{ authApplication.name }}</p>
        <p>{{ authApplication.website }}</p>
      </div>
      <p class="p-4">
        {{
          t(
            "You'll be able to revoke access for this application in your account settings."
          )
        }}
      </p>
      <div class="">
        <div
          v-if="collapses.length === 0"
          class="rounded-lg bg-mbz-danger shadow-xl my-6 p-4 flex items-center gap-2"
        >
          <AlertCircle :size="42" />
          <p>
            {{
              t(
                "This application didn't ask for known permissions. It's likely the request is incorrect."
              )
            }}
          </p>
        </div>
        <p v-else class="px-4 font-bold">
          {{ t("This application asks for the following permissions:") }}
        </p>
        <o-collapse
          class="mt-3 border-b pb-2 border-zinc-700 text-black dark:text-white"
          :class="{
            'bg-mbz-warning dark:!text-black': collapse?.type === 'warning',
          }"
          animation="slide"
          v-for="(collapse, index) of collapses"
          :key="index"
          :open="isOpen === index"
          @open="isOpen = index"
        >
          <template #trigger="props">
            <div class="flex py-1" role="button">
              <o-icon :icon="collapse.icon" class="px-2" />
              <p class="font-bold text-lg p-2 flex-1">
                {{ collapse.title }}
              </p>
              <a
                class="flex items-center cursor-pointer p-3 justify-center self-end"
              >
                <o-icon :icon="props.open ? 'chevron-up' : 'chevron-down'">
                </o-icon>
              </a>
            </div>
          </template>
          <div class="p-2">
            <div class="content">
              {{ collapse.text }}
            </div>
          </div>
        </o-collapse>
      </div>
      <div class="flex gap-3 p-4">
        <o-button
          :disabled="collapses.length === 0"
          @click="() => authorize()"
          >{{ t("Authorize") }}</o-button
        >
        <o-button outlined tag="router-link" :to="{ name: RouteName.HOME }">{{
          t("Decline")
        }}</o-button>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useHead } from "@vueuse/head";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";
import { AUTORIZE_APPLICATION } from "@/graphql/application";
import RouteName from "@/router/name";
import { IApplication } from "@/types/application.model";
import { scope } from "./scopes";
import AlertCircle from "vue-material-design-icons/AlertCircle.vue";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  authApplication: IApplication;
  redirectURI?: string | null;
  state?: string | null;
  scope?: string | null;
}>();

const isOpen = ref<number>(-1);

const collapses = computed(() =>
  (props.scope ?? "")
    .split(" ")
    .map((localScope) => scope[localScope])
    .filter((localScope) => localScope)
);

const { mutate: authorizeMutation, onDone: onAuthorizeMutationDone } =
  useMutation<
    {
      authorizeApplication: {
        code: string;
        state: string;
        clientId: string;
        scope: string;
      };
    },
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
  const localClientId = data?.authorizeApplication?.clientId;
  const localScope = data?.authorizeApplication?.scope;
  const returnedState = data?.authorizeApplication?.state ?? "";

  if (!code || !localClientId || !localScope) return;

  if (props.redirectURI) {
    const params = new URLSearchParams(
      Object.entries({
        code,
        state: returnedState,
        client_id: localClientId,
        scope: localScope,
      })
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
