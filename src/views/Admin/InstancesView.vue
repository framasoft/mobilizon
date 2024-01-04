<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        { text: t('Instances') },
      ]"
    />
    <section>
      <h1 class="title">{{ t("Instances") }}</h1>
      <form @submit="followInstance" class="my-4">
        <o-field
          :label="t('Follow a new instance')"
          horizontal
          label-for="newRelayAddress"
        >
          <o-field grouped group-multiline expanded size="large">
            <p class="control">
              <o-input
                id="newRelayAddress"
                v-model="newRelayAddress"
                :placeholder="t('Ex: mobilizon.fr')"
              />
            </p>
            <p class="control">
              <o-button variant="primary" native-type="submit">{{
                t("Add an instance")
              }}</o-button>
              <o-loading
                :is-full-page="true"
                v-model="followInstanceLoading"
                :can-cancel="false"
              />
            </p>
          </o-field>
        </o-field>
      </form>
      <div class="flex flex-wrap gap-2">
        <o-field :label="t('Follow status')">
          <o-radio
            v-model="followStatus"
            :native-value="InstanceFilterFollowStatus.ALL"
            >{{ t("All") }}</o-radio
          >
          <o-radio
            v-model="followStatus"
            :native-value="InstanceFilterFollowStatus.FOLLOWING"
            >{{ t("Following") }}</o-radio
          >
          <o-radio
            v-model="followStatus"
            :native-value="InstanceFilterFollowStatus.FOLLOWED"
            >{{ t("Followed") }}</o-radio
          >
        </o-field>
        <o-field
          :label="t('Domain or instance name')"
          label-for="domain-filter"
          class="flex-auto"
        >
          <o-input
            id="domain-filter"
            :placeholder="t('mobilizon-instance.tld')"
            v-model="filterDomain"
          />
        </o-field>
      </div>
      <div v-if="instances && instances.elements.length > 0" class="my-3">
        <router-link
          :to="{
            name: RouteName.INSTANCE,
            params: { domain: instance.domain },
          }"
          class="min-w-0 flex items-center mb-2 rounded bg-mbz-yellow-alt-300 hover:bg-mbz-yellow-alt-200 dark:bg-mbz-purple-600 dark:hover:bg-mbz-purple-700 p-4 flex-wrap md:flex-nowrap justify-center gap-x-2 gap-y-3"
          v-for="instance in instances.elements"
          :key="instance.domain"
        >
          <div class="flex-1 overflow-hidden flex items-center gap-1">
            <img
              class="w-12"
              v-if="instance.software === 'Mobilizon'"
              src="/img/logo.svg"
              alt=""
            />
            <mastodon-logo
              class="w-8 mx-2"
              alt=""
              v-else-if="instance.software?.toLowerCase() === 'mastodon'"
            />
            <img
              class="w-8 mx-2"
              v-else-if="instance.software?.toLowerCase() === 'gancio'"
              src="/img/gancio.png"
              alt=""
            />
            <img
              class="w-8 mx-2"
              v-else-if="instance.software?.toLowerCase() === 'wordpress'"
              src="/img/wordpress-logo.svg"
              alt=""
            />
            <CloudQuestion class="mx-1.5" v-else :size="36" />

            <div class="">
              <h3
                class="text-lg truncate font-bold line-clamp-1 text-slate-800 dark:text-slate-100"
                v-if="instance.instanceName"
              >
                {{ instance.instanceName }}
              </h3>
              <h3
                class="text-lg truncate font-bold text-slate-800 dark:text-slate-100"
                v-else
              >
                {{ instance.domain }}
              </h3>
              <div>
                <div class="flex flex-wrap gap-x-2 gap-y-1">
                  <p
                    v-if="instance.instanceName"
                    class="min-w-0 inline-flex gap-1 truncate text-slate-700 dark:text-slate-300"
                  >
                    <o-icon icon="web" />
                    <span>{{ instance.domain }}</span>
                  </p>
                  <p
                    v-if="instance.software"
                    class="capitalize text-slate-700 dark:text-slate-300 inline-flex gap-1"
                  >
                    <o-icon icon="server" />
                    {{ instance.software }}
                  </p>
                </div>
                <div>
                  <p
                    class="inline-flex gap-1 text-slate-700 dark:text-slate-300"
                    v-if="
                      instance.followedStatus === InstanceFollowStatus.APPROVED
                    "
                  >
                    <o-icon icon="inbox-arrow-down" />
                    {{ t("Followed") }}
                  </p>
                  <p
                    class="inline-flex gap-1 text-slate-700 dark:text-slate-300"
                    v-else-if="
                      instance.followedStatus === InstanceFollowStatus.PENDING
                    "
                  >
                    <o-icon icon="inbox-arrow-down" />
                    {{ t("Followed, pending response") }}
                  </p>
                  <p
                    class="inline-flex gap-1 text-slate-700 dark:text-slate-300"
                    v-if="
                      instance.followerStatus == InstanceFollowStatus.APPROVED
                    "
                  >
                    <o-icon icon="inbox-arrow-up" />
                    {{ t("Follows us") }}
                  </p>
                  <p
                    class="inline-flex gap-1 text-slate-700 dark:text-slate-300"
                    v-else-if="
                      instance.followerStatus == InstanceFollowStatus.PENDING
                    "
                  >
                    <o-icon icon="inbox-arrow-up" />
                    {{ t("Follows us, pending approval") }}
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="flex-none flex gap-3 ltr:ml-3 rtl:mr-3">
            <p class="flex flex-col text-center">
              <span class="text-xl">{{ instance.eventCount }}</span
              ><span class="text-sm">{{ t("Events") }}</span>
            </p>
            <p class="flex flex-col text-center">
              <span class="text-xl">{{ instance.personCount }}</span
              ><span class="text-sm">{{ t("Profiles") }}</span>
            </p>
          </div>
        </router-link>
        <o-pagination
          v-show="instances.total > INSTANCES_PAGE_LIMIT"
          :total="instances.total"
          v-model:current="instancePage"
          :per-page="INSTANCES_PAGE_LIMIT"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
        >
        </o-pagination>
      </div>
      <div v-else-if="instances && instances.elements.length == 0">
        <empty-content icon="lan-disconnect" :inline="true">
          {{ t("No instance found.") }}
          <template #desc>
            <span v-if="hasFilter">
              {{
                t(
                  "No instances match this filter. Try resetting filter fields?"
                )
              }}
            </span>
            <span v-else>
              {{ t("You haven't interacted with other instances yet.") }}
            </span>
          </template>
        </empty-content>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { ADD_INSTANCE, INSTANCES } from "@/graphql/admin";
import { Paginate } from "@/types/paginate";
import RouteName from "../../router/name";
import { IInstance } from "@/types/instance.model";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import {
  InstanceFilterFollowStatus,
  InstanceFollowStatus,
} from "@/types/enums";
import { useI18n } from "vue-i18n";
import {
  enumTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject, ref, watch } from "vue";
import { useRouter } from "vue-router";
import { useHead } from "@unhead/vue";
import CloudQuestion from "../../../node_modules/vue-material-design-icons/CloudQuestion.vue";
import { Notifier } from "@/plugins/notifier";
import MastodonLogo from "@/components/Share/MastodonLogo.vue";

const INSTANCES_PAGE_LIMIT = 10;

const instancePage = useRouteQuery("page", 1, integerTransformer);
const filterDomain = useRouteQuery("filterDomain", "");
const followStatus = useRouteQuery(
  "followStatus",
  InstanceFilterFollowStatus.ALL,
  enumTransformer(InstanceFilterFollowStatus)
);

const { result: instancesResult } = useQuery<{
  instances: Paginate<IInstance>;
}>(
  INSTANCES,
  () => ({
    page: instancePage.value,
    limit: INSTANCES_PAGE_LIMIT,
    filterDomain: filterDomain.value,
    filterFollowStatus: followStatus.value,
  }),
  { debounce: 500 }
);

watch([filterDomain, followStatus], () => {
  instancePage.value = 1;
});

const instances = computed(() => instancesResult.value?.instances);

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Federation")),
});

const followInstanceLoading = ref(false);

const newRelayAddress = ref("");

// relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };

// relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };

const hasFilter = computed((): boolean => {
  return (
    followStatus.value !== InstanceFilterFollowStatus.ALL ||
    filterDomain.value !== ""
  );
});

const router = useRouter();

const { mutate, onDone, onError } = useMutation<{
  addInstance: IInstance;
}>(ADD_INSTANCE);

onDone(({ data }) => {
  newRelayAddress.value = "";
  followInstanceLoading.value = false;
  router.push({
    name: RouteName.INSTANCE,
    params: { domain: data?.addInstance.domain },
  });
});

const notifier = inject<Notifier>("notifier");

onError((error) => {
  if (error.message) {
    if (error.graphQLErrors && error.graphQLErrors.length > 0) {
      notifier?.error(error.graphQLErrors[0].message);
    }
  }
  followInstanceLoading.value = false;
});

const followInstance = async (e: Event): Promise<void> => {
  e.preventDefault();
  followInstanceLoading.value = true;
  const domain = newRelayAddress.value.trim(); // trim to fix copy and paste domain name spaces and tabs
  mutate({
    domain,
  });
};
</script>
<style lang="scss" scoped>
.tab-item {
  form {
    margin-bottom: 1.5rem;
  }
}

a {
  text-decoration: none !important;
}
</style>
