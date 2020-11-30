<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MODERATION }">{{
            $t("Moderation")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.REPORTS }">{{
            $t("Reports")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section>
      <b-field>
        <b-radio-button
          v-model="filterReports"
          :native-value="ReportStatusEnum.OPEN"
          >{{ $t("Open") }}</b-radio-button
        >
        <b-radio-button
          v-model="filterReports"
          :native-value="ReportStatusEnum.RESOLVED"
          >{{ $t("Resolved") }}</b-radio-button
        >
        <b-radio-button
          v-model="filterReports"
          :native-value="ReportStatusEnum.CLOSED"
          >{{ $t("Closed") }}</b-radio-button
        >
      </b-field>
      <ul v-if="reports.length > 0">
        <li v-for="report in reports" :key="report.id">
          <router-link
            :to="{ name: RouteName.REPORT, params: { reportId: report.id } }"
          >
            <report-card :report="report" />
          </router-link>
        </li>
      </ul>
      <div v-else>
        <b-message
          v-if="filterReports === ReportStatusEnum.OPEN"
          type="is-info"
        >
          {{ $t("No open reports yet") }}
        </b-message>
        <b-message
          v-if="filterReports === ReportStatusEnum.RESOLVED"
          type="is-info"
        >
          {{ $t("No resolved reports yet") }}
        </b-message>
        <b-message
          v-if="filterReports === ReportStatusEnum.CLOSED"
          type="is-info"
        >
          {{ $t("No closed reports yet") }}
        </b-message>
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { IReport } from "@/types/report.model";
import { REPORTS } from "@/graphql/report";
import ReportCard from "@/components/Report/ReportCard.vue";
import { ReportStatusEnum } from "@/types/enums";
import RouteName from "../../router/name";

@Component({
  components: {
    ReportCard,
  },
  apollo: {
    reports: {
      query: REPORTS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          status: this.filterReports,
        };
      },
      pollInterval: 120000, // 2 minutes
    },
  },
})
export default class ReportList extends Vue {
  reports?: IReport[] = [];

  RouteName = RouteName;

  ReportStatusEnum = ReportStatusEnum;

  filterReports: ReportStatusEnum = ReportStatusEnum.OPEN;

  @Watch("$route.params.filter", { immediate: true })
  onRouteFilterChanged(val: string): void {
    if (!val) return;
    const filter = val.toUpperCase();
    if (filter in ReportStatusEnum) {
      this.filterReports = filter as ReportStatusEnum;
    }
  }

  @Watch("filterReports", { immediate: true })
  async onFilterChanged(val: string): Promise<void> {
    await this.$router.push({
      name: RouteName.REPORTS,
      params: { filter: val.toLowerCase() },
    });
  }
}
</script>

<style lang="scss" scoped>
section > ul li > a {
  text-decoration: none;
}
</style>
