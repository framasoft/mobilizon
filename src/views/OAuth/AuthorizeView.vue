<template>
  <div class="container mx-auto w-96">
    <div v-show="authApplicationLoading && !resultCode">
      <o-skeleton active size="large" class="mt-6" />
      <o-skeleton active width="80%" />
      <div
        class="rounded-lg bg-mbz-warning shadow-xl my-6 p-4 flex items-center gap-2"
      >
        <div>
          <o-skeleton circle active width="42px" height="42px" />
        </div>
        <div class="w-full">
          <o-skeleton active />
          <o-skeleton active />
          <o-skeleton active />
        </div>
      </div>
      <div class="rounded-lg bg-white shadow-xl my-6">
        <div class="p-4 pb-0">
          <p class="text-3xl"><o-skeleton active size="large" /></p>
          <o-skeleton active width="40%" />
        </div>
        <div class="flex gap-3 p-4">
          <o-skeleton active />
          <o-skeleton active />
        </div>
      </div>
    </div>
    <AuthorizeApplication
      v-if="authApplication"
      v-show="!authApplicationLoading && !authApplicationError && !resultCode"
      :auth-application="authApplication"
      :redirectURI="redirectURI"
      :state="state"
      :scope="scope"
    />
    <div v-show="authApplicationError">
      <div
        class="rounded-lg text-white bg-mbz-danger shadow-xl my-6 p-4 flex items-center gap-2"
        v-if="authApplicationGraphError?.code === 'application_not_found'"
      >
        <AlertCircle :size="42" />
        <div>
          <p class="font-bold">
            {{ t("Application not found") }}
          </p>
          <p>{{ t("The provided application was not found.") }}</p>
        </div>
      </div>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.HOME }"
        >{{ t("Back to homepage") }}</o-button
      >
    </div>
    <div
      v-if="resultCode"
      class="rounded-lg bg-white shadow-xl my-6 p-4 flex items-center gap-2"
    >
      <div>
        <p class="font-bold">
          {{ t("Your application code") }}
        </p>
        <p>
          {{
            t(
              "You need to provide the following code to your application. It will only be valid for a few minutes."
            )
          }}
        </p>
        <p class="text-4xl">{{ resultCode }}</p>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useRouteQuery } from "vue-use-route-query";
import { useHead } from "@unhead/vue";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useQuery } from "@vue/apollo-composable";
import { AUTH_APPLICATION } from "@/graphql/application";
import { IApplication } from "@/types/application.model";
import AlertCircle from "vue-material-design-icons/AlertCircle.vue";
import type { AbsintheGraphQLError } from "@/types/errors.model";
import RouteName from "@/router/name";
import AuthorizeApplication from "@/components/OAuth/AuthorizeApplication.vue";

const { t } = useI18n({ useScope: "global" });

const clientId = useRouteQuery("client_id", null);
const redirectURI = useRouteQuery("redirect_uri", null);
const state = useRouteQuery("state", null);
const scope = useRouteQuery("scope", null);

const resultCode = ref<string | null>(null);

const {
  result: authApplicationResult,
  loading: authApplicationLoading,
  error: authApplicationError,
} = useQuery<{ authApplication: IApplication }, { clientId: string }>(
  AUTH_APPLICATION,
  () => ({
    clientId: clientId.value as string,
  }),
  () => ({
    enabled: clientId.value !== null,
  })
);

const authApplication = computed(
  () => authApplicationResult.value?.authApplication
);

const authApplicationGraphError = computed(
  () => authApplicationError.value?.graphQLErrors[0] as AbsintheGraphQLError
);

useHead({
  title: computed(() => t("Authorize application")),
});
</script>
