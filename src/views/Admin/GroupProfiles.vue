<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MODERATION, text: t('Moderation') },
        {
          name: RouteName.ADMIN_GROUPS,
          text: t('Groups'),
        },
      ]"
    />
    <div class="buttons" v-if="showCreateGroupsButton">
      <router-link
        class="button is-primary"
        :to="{ name: RouteName.CREATE_GROUP }"
        >{{ t("Create group") }}</router-link
      >
    </div>
    <div v-if="groups">
      <div class="flex gap-2">
        <o-switch v-model="local">{{ t("Local") }}</o-switch>
        <o-switch v-model="suspended">{{ t("Suspended") }}</o-switch>
      </div>
      <o-table
        :data="groups.elements"
        :loading="loading"
        paginated
        backend-pagination
        backend-filtering
        :debounce-search="500"
        v-model:current-page="page"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="groups.total"
        :per-page="PROFILES_PER_PAGE"
        @page-change="onPageChange"
        @filters-change="onFiltersChange"
      >
        <o-table-column
          field="preferredUsername"
          :label="t('Username')"
          searchable
        >
          <template #searchable="props">
            <o-input
              :aria-label="t('Filter')"
              v-model="props.filters.preferredUsername"
              :placeholder="t('Filter')"
              icon="magnify"
            />
          </template>
          <template #default="props">
            <router-link
              class="profile"
              :to="{
                name: RouteName.ADMIN_GROUP_PROFILE,
                params: { id: props.row.id },
              }"
            >
              <article class="flex gap-1">
                <figure class="" v-if="props.row.avatar">
                  <img
                    :src="props.row.avatar.url"
                    :alt="props.row.avatar.alt || ''"
                    width="48"
                    height="48"
                    class="rounded-full"
                  />
                </figure>
                <AccountGroup v-else :size="48" />
                <div class="">
                  <div class="prose dark:prose-invert">
                    <p v-if="props.row.name" class="font-bold mb-0">
                      {{ props.row.name }}
                    </p>
                    <span class="text-sm"
                      >@{{ props.row.preferredUsername }}</span
                    >
                  </div>
                </div>
              </article>
            </router-link>
          </template>
        </o-table-column>

        <o-table-column field="domain" :label="t('Domain')" searchable>
          <template #searchable="props">
            <o-input
              :aria-label="t('Filter')"
              v-model="props.filters.domain"
              :placeholder="t('Filter')"
              icon="magnify"
            />
          </template>
          <template #default="props">
            {{ props.row.domain }}
          </template>
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ t("No group matches the filters") }}
          </empty-content>
        </template>
      </o-table>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { LIST_GROUPS } from "@/graphql/group";
import RouteName from "../../router/name";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { useRestrictions } from "@/composition/apollo/config";
import { useQuery } from "@vue/apollo-composable";
import {
  booleanTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";
import { computed } from "vue";
import { Paginate } from "@/types/paginate";
import { IGroup } from "@/types/actor";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";

const PROFILES_PER_PAGE = 10;

const { restrictions } = useRestrictions();

const preferredUsername = useRouteQuery("preferredUsername", "");
const name = useRouteQuery("name", "");
const domain = useRouteQuery("domain", "");

const local = useRouteQuery("local", domain.value === "", booleanTransformer);
const suspended = useRouteQuery("suspended", false, booleanTransformer);
const page = useRouteQuery("page", 1, integerTransformer);

const {
  result: groupsResult,
  fetchMore,
  loading,
} = useQuery<{
  groups: Paginate<IGroup>;
}>(LIST_GROUPS, () => ({
  preferredUsername: preferredUsername.value,
  name: name.value,
  domain: domain.value,
  local: local.value,
  suspended: suspended.value,
  page: page.value,
  limit: PROFILES_PER_PAGE,
}));

const groups = computed(() => groupsResult.value?.groups);

const { t } = useI18n({ useScope: "global" });

useHead({ title: computed(() => t("Groups")) });

const onPageChange = async (): Promise<void> => {
  await doFetchMore();
};

const showCreateGroupsButton = computed((): boolean => {
  return !!restrictions.value?.onlyAdminCanCreateGroups;
});

const onFiltersChange = ({
  preferredUsername: newPreferredUsername,
  domain: newDomain,
}: {
  preferredUsername: string;
  domain: string;
}): void => {
  preferredUsername.value = newPreferredUsername;
  domain.value = newDomain;
  doFetchMore();
};

const doFetchMore = async (): Promise<void> => {
  await fetchMore({
    variables: {
      preferredUsername: preferredUsername.value,
      name: name.value,
      domain: domain.value,
      local: local.value,
      suspended: suspended.value,
      page: page.value,
      limit: PROFILES_PER_PAGE,
    },
  });
};
</script>
<style lang="scss" scoped>
a.profile {
  text-decoration: none;
}
</style>
