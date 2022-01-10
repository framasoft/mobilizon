<template>
  <div>
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.MODERATION,
          text: $t('Moderation'),
        },
        {
          name: RouteName.REPORTS,
          text: $t('Reports'),
        },
      ]"
    />
    <section>
      <div class="flex flex-wrap gap-2">
        <b-field :label="$t('Report status')">
          <b-radio-button
            v-model="status"
            :native-value="ReportStatusEnum.OPEN"
            >{{ $t("Open") }}</b-radio-button
          >
          <b-radio-button
            v-model="status"
            :native-value="ReportStatusEnum.RESOLVED"
            >{{ $t("Resolved") }}</b-radio-button
          >
          <b-radio-button
            v-model="status"
            :native-value="ReportStatusEnum.CLOSED"
            >{{ $t("Closed") }}</b-radio-button
          >
        </b-field>
        <b-field
          :label="$t('Domain')"
          label-for="domain-filter"
          class="flex-auto"
        >
          <b-input
            id="domain-filter"
            :placeholder="$t('mobilizon-instance.tld')"
            :value="filterDomain"
            @input="debouncedUpdateDomainFilter"
          />
        </b-field>
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
          {{ $t("No open reports yet") }}
        </empty-content>
        <empty-content
          icon="chat-alert"
          inline
          v-if="status === ReportStatusEnum.RESOLVED"
        >
          {{ $t("No resolved reports yet") }}
        </empty-content>
        <empty-content
          icon="chat-alert"
          inline
          v-if="status === ReportStatusEnum.CLOSED"
        >
          {{ $t("No closed reports yet") }}
        </empty-content>
      </div>
      <b-pagination
        :total="reports.total"
        v-model="page"
        :simple="true"
        :per-page="REPORT_PAGE_LIMIT"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      >
      </b-pagination>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { IReport } from "@/types/report.model";
import { REPORTS } from "@/graphql/report";
import ReportCard from "@/components/Report/ReportCard.vue";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { ReportStatusEnum } from "@/types/enums";
import RouteName from "../../router/name";
import VueRouter from "vue-router";
import { Paginate } from "@/types/paginate";
import debounce from "lodash/debounce";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const REPORT_PAGE_LIMIT = 10;

@Component({
  components: {
    ReportCard,
    EmptyContent,
  },
  apollo: {
    reports: {
      fetchPolicy: "cache-and-network",
      query: REPORTS,
      variables() {
        return {
          page: this.page,
          status: this.status,
          limit: REPORT_PAGE_LIMIT,
          domain: this.filterDomain,
        };
      },
      pollInterval: 120000, // 2 minutes
    },
  },
  metaInfo() {
    return {
      title: this.$t("Reports") as string,
    };
  },
})
export default class ReportList extends Vue {
  reports?: Paginate<IReport> = { elements: [], total: 0 };

  RouteName = RouteName;

  ReportStatusEnum = ReportStatusEnum;

  filterReports: ReportStatusEnum = ReportStatusEnum.OPEN;

  REPORT_PAGE_LIMIT = REPORT_PAGE_LIMIT;

  data(): Record<string, unknown> {
    return {
      debouncedUpdateDomainFilter: debounce(this.updateDomainFilter, 500),
    };
  }

  async updateDomainFilter(domain: string) {
    this.filterDomain = domain;
  }

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter({
      page: page.toString(),
    });
  }

  get status(): ReportStatusEnum {
    const filter = (this.$route.query.status || "") as string;
    if (filter in ReportStatusEnum) {
      return filter as ReportStatusEnum;
    }
    return ReportStatusEnum.OPEN;
  }

  set status(status: ReportStatusEnum) {
    this.pushRouter({ status });
  }

  get filterDomain(): string {
    return (this.$route.query.domain as string) || "";
  }

  set filterDomain(domain: string) {
    this.pushRouter({ domain });
  }

  protected async pushRouter(args: Record<string, string>): Promise<void> {
    try {
      await this.$router.push({
        name: RouteName.REPORTS,
        params: this.$route.params,
        query: { ...this.$route.query, ...args },
      });
    } catch (e) {
      if (isNavigationFailure(e, NavigationFailureType.redirected)) {
        throw Error(e.toString());
      }
    }
  }
}
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
