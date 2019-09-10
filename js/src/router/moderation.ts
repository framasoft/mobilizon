import { RouteConfig } from 'vue-router';
import ReportList from '@/views/Moderation/ReportList.vue';
import Report from '@/views/Moderation/Report.vue';
import Logs from '@/views/Moderation/Logs.vue';

export enum ModerationRouteName {
  REPORTS = 'Reports',
  REPORT = 'Report',
  LOGS = 'Logs',
}

export const moderationRoutes: RouteConfig[] = [
  {
    path: '/moderation/reports/:filter?',
    name: ModerationRouteName.REPORTS,
    component: ReportList,
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: '/moderation/report/:reportId',
    name: ModerationRouteName.REPORT,
    component: Report,
    props: true,
    meta: { requiredAuth: true },
  },
  {
    path: '/moderation/logs',
    name: ModerationRouteName.LOGS,
    component: Logs,
    props: true,
    meta: { requiredAuth: true },
  },
];
