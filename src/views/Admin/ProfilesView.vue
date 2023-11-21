<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MODERATION, text: t('Moderation') },
        {
          name: RouteName.PROFILES,
          text: t('Profiles'),
        },
      ]"
    />
    <div v-if="persons">
      <div class="flex gap-2">
        <o-switch v-model="local">{{ t("Local") }}</o-switch>
        <o-switch v-model="suspended">{{ t("Suspended") }}</o-switch>
      </div>
      <o-table
        :data="persons.elements"
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
        :total="persons.total"
        :per-page="PROFILES_PER_PAGE"
        @filters-change="onFiltersChange"
      >
        <o-table-column
          field="preferredUsername"
          :label="t('Username')"
          searchable
        >
          <template #searchable="props">
            <o-input
              v-model="props.filters.preferredUsername"
              :aria-label="t('Filter')"
              :placeholder="t('Filter')"
              icon="magnify"
            />
          </template>
          <template #default="props">
            <router-link
              class="profile"
              :to="{
                name: RouteName.ADMIN_PROFILE,
                params: { id: props.row.id },
              }"
            >
              <article class="flex gap-2">
                <figure class="" v-if="props.row.avatar">
                  <img
                    :src="props.row.avatar.url"
                    :alt="props.row.avatar.alt || ''"
                    width="48"
                    height="48"
                    class="rounded-full"
                  />
                </figure>
                <Account v-else :size="48" />
                <div class="">
                  <div class="prose dark:prose-invert">
                    <strong v-if="props.row.name">{{ props.row.name }}</strong
                    ><br v-if="props.row.name" />
                    <small>@{{ props.row.preferredUsername }}</small>
                  </div>
                </div>
              </article>
            </router-link>
          </template>
        </o-table-column>

        <o-table-column field="domain" :label="t('Domain')" searchable>
          <template #searchable="props">
            <o-input
              v-model="props.filters.domain"
              :aria-label="t('Filter')"
              :placeholder="t('Filter')"
              icon="magnify"
            />
          </template>
          <template #default="props">
            {{ props.row.domain }}
          </template>
        </o-table-column>
        <template #empty>
          <empty-content icon="account" :inline="true">
            {{ t("No profile matches the filters") }}
          </empty-content>
        </template>
      </o-table>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { LIST_PROFILES } from "@/graphql/actor";
import RouteName from "@/router/name";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { useQuery } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { computed } from "vue";
import { useHead } from "@unhead/vue";
import {
  useRouteQuery,
  booleanTransformer,
  integerTransformer,
} from "vue-use-route-query";
import { Paginate } from "@/types/paginate";
import { IPerson } from "@/types/actor/person.model";
import Account from "vue-material-design-icons/Account.vue";

const PROFILES_PER_PAGE = 10;

const preferredUsername = useRouteQuery("preferredUsername", "");
const name = useRouteQuery("name", "");
const domain = useRouteQuery("domain", "");

const local = useRouteQuery("local", domain.value === "", booleanTransformer);
const suspended = useRouteQuery("suspended", false, booleanTransformer);
const page = useRouteQuery("page", 1, integerTransformer);

const {
  result: personResult,
  loading,
  fetchMore,
} = useQuery<{ persons: Paginate<IPerson> }>(LIST_PROFILES, () => ({
  preferredUsername: preferredUsername.value,
  name: name.value,
  domain: domain.value,
  local: local.value,
  suspended: suspended.value,
  page: page.value,
  limit: PROFILES_PER_PAGE,
}));

const persons = computed(() => personResult.value?.persons);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Profiles")),
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
  fetchMore({});
};
</script>
<style lang="scss" scoped>
a.profile {
  text-decoration: none;
}
</style>
