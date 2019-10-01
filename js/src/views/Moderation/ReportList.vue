<template>
    <section class="container">
        <nav class="breadcrumb" aria-label="breadcrumbs">
            <ul>
                <li><router-link :to="{ name: AdminRouteName.DASHBOARD }">Dashboard</router-link></li>
                <li class="is-active"><router-link :to="{ name: ModerationRouteName.REPORTS }" aria-current="page">Reports</router-link></li>
            </ul>
        </nav>
        <b-field>
            <b-radio-button v-model="filterReports"
                            :native-value="ReportStatusEnum.OPEN">
                Ouvert
            </b-radio-button>
            <b-radio-button v-model="filterReports"
                            :native-value="ReportStatusEnum.RESOLVED">
                Résolus
            </b-radio-button>
            <b-radio-button v-model="filterReports"
                            :native-value="ReportStatusEnum.CLOSED">
                Fermés
            </b-radio-button>
        </b-field>
        <ul v-if="reports.length > 0">
            <li v-for="report in reports">
                <router-link :to="{ name: ModerationRouteName.REPORT, params: { reportId: report.id } }">
                    <report-card :report="report" />
                </router-link>
            </li>
        </ul>
        <div v-else>
            <b-message v-if="filterReports === ReportStatusEnum.OPEN" type="is-info">No open reports yet</b-message>
            <b-message v-if="filterReports === ReportStatusEnum.RESOLVED" type="is-info">No resolved reports yet</b-message>
            <b-message v-if="filterReports === ReportStatusEnum.CLOSED" type="is-info">No closed reports yet</b-message>
        </div>
    </section>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { IReport, ReportStatusEnum } from '@/types/report.model';
import { REPORTS } from '@/graphql/report';
import ReportCard from '@/components/Report/ReportCard.vue';
import { AdminRouteName } from '@/router/admin';
import { ModerationRouteName } from '@/router/moderation';

@Component({
  components: {
    ReportCard,
  },
  apollo: {
    reports: {
      query: REPORTS,
      fetchPolicy: 'no-cache',
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
  AdminRouteName = AdminRouteName;
  ModerationRouteName = ModerationRouteName;
  ReportStatusEnum = ReportStatusEnum;
  filterReports: ReportStatusEnum = ReportStatusEnum.OPEN;

  @Watch('$route.params.filter', { immediate: true })
        onRouteFilterChanged (val: string) {
    if (!val) return;
    const filter = val.toUpperCase();
    if (filter in ReportStatusEnum) {
      this.filterReports = filter as ReportStatusEnum;
    }
  }

  @Watch('filterReports', { immediate: true })
        async onFilterChanged (val: string) {
    await this.$router.push({ name: ModerationRouteName.REPORTS, params: { filter: val.toLowerCase() } });
  }
}
</script>
<style lang="scss">
    .container li {
        margin: 10px auto;
    }
</style>