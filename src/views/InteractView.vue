<template>
  <div class="container mx-auto section">
    <o-notification v-if="loading">
      {{ t("Redirecting to content…") }}
    </o-notification>
    <o-notification v-if="!isURI" variant="danger">
      {{ t("Resource provided is not an URL") }}
    </o-notification>
    <o-notification
      :title="t('Error')"
      variant="danger"
      has-icon
      :closable="false"
      v-if="!loading && errors.length > 0"
    >
      <p v-for="error in errors" :key="error">
        <b>{{ error }}</b>
      </p>
      <p>
        {{
          t(
            "It is possible that the content is not accessible on this instance, because this instance has blocked the profiles or groups behind this content."
          )
        }}
      </p>
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import { INTERACT } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import { IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../router/name";
import { GraphQLError } from "graphql";
import { useQuery } from "@vue/apollo-composable";
import { computed, reactive } from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { useRouteQuery } from "vue-use-route-query";
import { useHead } from "@vueuse/head";

const router = useRouter();
const { t } = useI18n({ useScope: "global" });

const uri = useRouteQuery("uri", "");

const isURI = computed((): boolean => {
  try {
    const url = new URL(uri.value);
    return url instanceof URL;
  } catch (e) {
    return false;
  }
});

const errors = reactive<string[]>([]);

const { onResult, onError, loading } = useQuery<{
  interact: (IEvent | IGroup) & { __typename: string };
}>(
  INTERACT,
  () => ({
    uri: uri.value,
  }),
  () => ({
    enabled: isURI.value === true,
  })
);

onResult(async (result) => {
  if (result.loading) return;
  if (!result.data) {
    errors.push(t("This URL is not supported"));
    return;
  }
  const interact = result.data.interact;
  switch (interact.__typename) {
    case "Group":
      await router.replace({
        name: RouteName.GROUP,
        params: { preferredUsername: usernameWithDomain(interact as IGroup) },
      });
      break;
    case "Event":
      await router.replace({
        name: RouteName.EVENT,
        params: { uuid: (interact as IEvent).uuid },
      });
      break;
    default:
      errors.push(t("This URL is not supported"));
  }
});

onError(({ graphQLErrors, networkError }) => {
  if (networkError) {
    errors.push(networkError.message);
  }
  errors.push(...graphQLErrors.map((error: GraphQLError) => error.message));
});

useHead({
  title: computed(() => t("Interact with a remote content")),
});
</script>
