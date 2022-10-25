<template>
  <div>
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.MODERATION,
          text: t('Moderation'),
        },
        {
          name: RouteName.REPORTS,
          text: t('Reports'),
        },
      ]"
    />
    <section>
      <div class="flex flex-wrap gap-2">
        <o-field :label="t('Report status')">
          <o-radio v-model="status" :native-value="ReportStatusEnum.OPEN">{{
            t("Open")
          }}</o-radio>
          <o-radio v-model="status" :native-value="ReportStatusEnum.RESOLVED">{{
            t("Resolved")
          }}</o-radio>
          <o-radio v-model="status" :native-value="ReportStatusEnum.CLOSED">{{
            t("Closed")
          }}</o-radio>
        </o-field>
        <o-field
          :label="t('Domain')"
          label-for="domain-filter"
          class="flex-auto"
        >
          <o-input
            id="domain-filter"
            :placeholder="t('mobilizon-instance.tld')"
            :value="filterDomain"
            @input="debouncedUpdateDomainFilter"
          />
        </o-field>
      </div>
      <ul v-if="reports.elements.length > 0">
        <li v-for="report in reports.elements" :key="report.id">
          <router-link
            :to="{ name: RouteName.REPORT, params: { reportId: report.id } }"
          >
            <report-card :report="report" />
          </router-link>
        </li>
      </ul>
      <div v-else class="no-reports">
        <empty-content
          icon="chat-alert"
          inline
          v-if="status === ReportStatusEnum.OPEN"
        >
          {{ t("No open reports yet") }}
        </empty-content>
        <empty-content
          icon="chat-alert"
          inline
          v-if="status === ReportStatusEnum.RESOLVED"
        >
          {{ t("No resolved reports yet") }}
        </empty-content>
        <empty-content
          icon="chat-alert"
          inline
          v-if="status === ReportStatusEnum.CLOSED"
        >
          {{ t("No closed reports yet") }}
        </empty-content>
      </div>
      <o-pagination
        :total="reports.total"
        v-model="page"
        :simple="true"
        :per-page="REPORT_PAGE_LIMIT"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
      >
      </o-pagination>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { IReport } from "@/types/report.model";
import { REPORTS } from "@/graphql/report";
import ReportCard from "@/components/Report/ReportCard.vue";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { ReportStatusEnum } from "@/types/enums";
import RouteName from "../../router/name";
import { Paginate } from "@/types/paginate";
import debounce from "lodash/debounce";
import { useQuery } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";
import { computed } from "vue";
import {
  enumTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";

const REPORT_PAGE_LIMIT = 10;
const page = useRouteQuery("page", 1, integerTransformer);
const filterDomain = useRouteQuery("filterDomain", "");
const status = useRouteQuery(
  "status",
  ReportStatusEnum.OPEN,
  enumTransformer(ReportStatusEnum)
);

const { result: reportsResult } = useQuery<{ reports: Paginate<IReport> }>(
  REPORTS,
  () => ({
    page: page.value,
    status: status.value,
    limit: REPORT_PAGE_LIMIT,
    domain: filterDomain.value,
  }),
  {
    fetchPolicy: "cache-and-network",
  }
);

const reports = computed(
  () => reportsResult.value?.reports ?? { elements: [], total: 0 }
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Reports")),
});

// const filterReports = ref<ReportStatusEnum>(ReportStatusEnum.OPEN);

const updateDomainFilter = (event: InputEvent) => {
  filterDomain.value = event.target?.value;
};

const debouncedUpdateDomainFilter = debounce(updateDomainFilter, 500);
</script>

<style lang="scss" scoped>
section {
  .no-reports {
    margin-bottom: 2rem;
  }
  & > ul li {
    margin: 0.5rem auto;

    & > a {
      text-decoration: none;
    }
  }
}
</style>
