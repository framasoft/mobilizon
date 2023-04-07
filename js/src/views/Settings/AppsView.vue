<template>
  <div v-if="loggedUser">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.AUTHORIZED_APPS,
          text: t('Apps'),
        },
        {
          name: RouteName.ACCOUNT_SETTINGS_GENERAL,
          text: t('General'),
        },
      ]"
    />
    <section>
      <h2>{{ t("Apps") }}</h2>
      <p>
        {{
          t(
            "These apps can access your account through the API. If you see here apps that you don't recognize, that don't work as expected or that you don't use anymore, you can revoke their access."
          )
        }}
      </p>
      <div v-if="authAuthorizedApplications.length > 0">
        <div
          class="flex justify-between items-center rounded-lg bg-white shadow-xl my-6"
          v-for="authAuthorizedApplication in authAuthorizedApplications"
          :key="authAuthorizedApplication.id"
        >
          <div class="p-4">
            <p class="text-3xl font-bold">
              {{ authAuthorizedApplication.application.name }}
            </p>
            <a
              v-if="authAuthorizedApplication.application.website"
              target="_blank"
              :href="authAuthorizedApplication.application.website"
              >{{
                urlToHostname(authAuthorizedApplication.application.website)
              }}</a
            >
            <p>
              <span v-if="authAuthorizedApplication.lastUsedAt">{{
                t("Last used on {last_used_date}", {
                  last_used_date: formatDateString(
                    authAuthorizedApplication.lastUsedAt
                  ),
                })
              }}</span>
              <span v-else>{{ t("Never used") }}</span> ⋅
              {{
                t("Authorized on {authorization_date}", {
                  authorization_date: formatDateString(
                    authAuthorizedApplication.insertedAt
                  ),
                })
              }}
            </p>
          </div>
          <div class="p-4">
            <o-button
              @click="
                () => revoke({ appTokenId: authAuthorizedApplication.id })
              "
              variant="danger"
              >{{ t("Revoke") }}</o-button
            >
          </div>
        </div>
      </div>
      <EmptyContent v-else icon="apps" inline>
        {{ t("No apps authorized yet") }}
      </EmptyContent>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { useLoggedUser } from "@/composition/apollo/user";
import {
  AUTH_AUTHORIZED_APPLICATIONS,
  REVOKED_AUTHORIZED_APPLICATION,
} from "@/graphql/application";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { computed, inject } from "vue";
import { useI18n } from "vue-i18n";
import RouteName from "../../router/name";
import { IUser } from "@/types/current-user.model";
import { formatDateString } from "@/filters/datetime";
import { Notifier } from "@/plugins/notifier";
import EmptyContent from "@/components/Utils/EmptyContent.vue";

const { t } = useI18n({ useScope: "global" });

const { loggedUser } = useLoggedUser();

const { result: authAuthorizedApplicationsResult } = useQuery<{
  loggedUser: Pick<IUser, "authAuthorizedApplications">;
}>(AUTH_AUTHORIZED_APPLICATIONS);

const authAuthorizedApplications = computed(
  () =>
    authAuthorizedApplicationsResult.value?.loggedUser
      ?.authAuthorizedApplications ?? []
);

const urlToHostname = (url: string | undefined): string | null => {
  if (!url) return null;
  try {
    return new URL(url).hostname;
  } catch (e) {
    return null;
  }
};

const { mutate: revoke, onDone: onRevokedApplication } = useMutation<
  { revokeApplicationToken: { id: string } },
  { appTokenId: string }
>(REVOKED_AUTHORIZED_APPLICATION, {
  update: (cache, { data: returnedData }) => {
    const data = cache.readQuery<{
      loggedUser: Pick<IUser, "authAuthorizedApplications">;
    }>({ query: AUTH_AUTHORIZED_APPLICATIONS });
    if (!data) return;
    if (!returnedData) return;
    const authorizedApplications =
      data.loggedUser.authAuthorizedApplications.filter(
        (app) => app.id !== returnedData.revokeApplicationToken.id
      );
    cache.writeQuery({
      query: AUTH_AUTHORIZED_APPLICATIONS,
      data: {
        ...data,
        loggedUser: {
          ...data.loggedUser,
          authAuthorizedApplications: authorizedApplications,
        },
      },
    });
  },
});

const notifier = inject<Notifier>("notifier");

onRevokedApplication(() => {
  notifier?.success(t("Application was revoked"));
});

useHead({
  title: computed(() => t("Apps")),
});
</script>
