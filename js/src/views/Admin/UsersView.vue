<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MODERATION, text: $t('Moderation') },
        {
          name: RouteName.USERS,
          text: $t('Users'),
        },
      ]"
    />
    <div v-if="users">
      <form @submit.prevent="activateFilters">
        <o-field class="mb-5" grouped group-multiline>
          <o-field :label="$t('Email')" expanded>
            <o-input trap-focus icon="email" v-model="emailFilterFieldValue" />
          </o-field>
          <o-field :label="$t('IP Address')" expanded>
            <o-input icon="web" v-model="ipFilterFieldValue" />
          </o-field>
          <p class="control self-end mb-0">
            <o-button variant="primary" native-type="submit">{{
              $t("Filter")
            }}</o-button>
          </p>
        </o-field>
      </form>
      <o-table
        :data="users.elements"
        :loading="usersLoading"
        paginated
        backend-pagination
        :debounce-search="500"
        v-model:current-page="page"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :show-detail-icon="true"
        :total="users.total"
        :per-page="USERS_PER_PAGE"
        @page-change="onPageChange"
      >
        <o-table-column field="id" width="40" numeric v-slot="props">
          {{ props.row.id }}
        </o-table-column>
        <o-table-column field="email" :label="$t('Email')">
          <template #default="props">
            <router-link
              :to="{
                name: RouteName.ADMIN_USER_PROFILE,
                params: { id: props.row.id },
              }"
              :class="{ disabled: props.row.disabled }"
            >
              {{ props.row.email }}
            </router-link>
          </template>
        </o-table-column>
        <o-table-column
          field="confirmedAt"
          :label="$t('Last seen on')"
          :centered="true"
          v-slot="props"
        >
          <template v-if="props.row.currentSignInAt">
            <time :datetime="props.row.currentSignInAt">
              {{ formatDateTimeString(props.row.currentSignInAt) }}
            </time>
          </template>
          <template v-else-if="props.row.confirmedAt"> - </template>
          <template v-else>
            {{ $t("Not confirmed") }}
          </template>
        </o-table-column>
        <o-table-column
          field="locale"
          :label="$t('Language')"
          :centered="true"
          v-slot="props"
        >
          {{ getLanguageNameForCode(props.row.locale) }}
        </o-table-column>
        <template #empty>
          <empty-content
            v-if="!usersLoading && emailFilter"
            :inline="true"
            icon="account"
          >
            {{ $t("No user matches the filters") }}
            <template #desc>
              <o-button variant="primary" @click="resetFilters">
                {{ $t("Reset filters") }}
              </o-button>
            </template>
          </empty-content>
        </template>
      </o-table>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { LIST_USERS } from "../../graphql/user";
import RouteName from "../../router/name";
import { LANGUAGES_CODES } from "@/graphql/admin";
import { IUser } from "@/types/current-user.model";
import { Paginate } from "@/types/paginate";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { useQuery } from "@vue/apollo-composable";
import { ILanguage } from "@/types/admin.model";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { formatDateTimeString } from "@/filters/datetime";

const USERS_PER_PAGE = 10;

const emailFilter = useRouteQuery("emailFilter", "");
const ipFilter = useRouteQuery("ipFilter", "");
const page = useRouteQuery("page", 1, integerTransformer);

const languagesCodes = computed((): string[] => {
  return (users.value?.elements ?? []).map((user: IUser) => user.locale);
});

const {
  result: usersResult,
  fetchMore,
  loading: usersLoading,
} = useQuery<{ users: Paginate<IUser> }>(LIST_USERS, () => ({
  email: emailFilter.value,
  currentSignInIp: ipFilter.value,
  page: page.value,
  limit: USERS_PER_PAGE,
}));

const users = computed(() => usersResult.value?.users);

const { result: languagesResult } = useQuery<{ languages: ILanguage[] }>(
  LANGUAGES_CODES,
  () => ({
    codes: languagesCodes.value,
  }),
  () => ({
    enabled: languagesCodes.value !== undefined,
  })
);

const languages = computed(() => languagesResult.value?.languages);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Users")),
});

const emailFilterFieldValue = ref(emailFilter.value);
const ipFilterFieldValue = ref(ipFilter.value);

const getLanguageNameForCode = (code: string): string => {
  return (
    (languages.value ?? []).find(({ code: languageCode }) => {
      return languageCode === code;
    })?.name || code
  );
};

const onPageChange = async (newPage: number): Promise<void> => {
  page.value = newPage;
  await fetchMore({
    variables: {
      email: emailFilter.value,
      currentSignInIp: ipFilter.value,
      page: page.value,
      limit: USERS_PER_PAGE,
    },
  });
};

const activateFilters = (): void => {
  emailFilter.value = emailFilterFieldValue.value;
  ipFilter.value = ipFilterFieldValue.value;
};

const resetFilters = (): void => {
  emailFilterFieldValue.value = "";
  ipFilterFieldValue.value = "";
  activateFilters();
};
</script>

<style lang="scss" scoped>
a.profile,
a.user-profile {
  text-decoration: none;
}
a.disabled {
  text-decoration: line-through;
}
</style>
