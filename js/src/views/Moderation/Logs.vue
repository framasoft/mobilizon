<template>
  <section>
    <ul v-if="actionLogs.length > 0">
      <li v-for="log in actionLogs">
        <div class="box">
          <img class="image" :src="log.actor.avatar.url" v-if="log.actor.avatar" />
          <span>@{{ log.actor.preferredUsername }}</span>
          <span v-if="log.action === ActionLogAction.REPORT_UPDATE_CLOSED">
            closed
            <router-link :to="{ name: RouteName.REPORT, params: { reportId: log.object.id } }"
              >report #{{ log.object.id }}</router-link
            >
          </span>
          <span v-else-if="log.action === ActionLogAction.REPORT_UPDATE_OPENED">
            reopened
            <router-link :to="{ name: RouteName.REPORT, params: { reportId: log.object.id } }"
              >report #{{ log.object.id }}</router-link
            >
          </span>
          <span v-else-if="log.action === ActionLogAction.REPORT_UPDATE_RESOLVED">
            marked
            <router-link :to="{ name: RouteName.REPORT, params: { reportId: log.object.id } }"
              >report #{{ log.object.id }}</router-link
            >as resolved
          </span>
          <span v-else-if="log.action === ActionLogAction.NOTE_CREATION">
            added a note on
            <router-link
              v-if="log.object.report"
              :to="{ name: RouteName.REPORT, params: { reportId: log.object.report.id } }"
              >report #{{ log.object.report.id }}</router-link
            >
            <span v-else>a non-existent report</span>
          </span>
          <span v-else-if="log.action === ActionLogAction.EVENT_DELETION"
            >deleted an event named « {{ log.object.title }} »</span
          >
          <br />
          <small>{{ log.insertedAt | formatDateTimeString }}</small>
        </div>
        <!--                <pre>{{ log }}</pre>-->
      </li>
    </ul>
    <div v-else>
      <b-message type="is-info">No moderation logs yet</b-message>
    </div>
  </section>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { IActionLog, ActionLogAction } from "@/types/report.model";
import { LOGS } from "@/graphql/report";
import ReportCard from "@/components/Report/ReportCard.vue";
import RouteName from "../../router/name";

@Component({
  components: {
    ReportCard,
  },
  apollo: {
    actionLogs: {
      query: LOGS,
    },
  },
})
export default class ReportList extends Vue {
  actionLogs?: IActionLog[] = [];

  ActionLogAction = ActionLogAction;

  RouteName = RouteName;
}
</script>
<style lang="scss" scoped>
img.image {
  display: inline;
  height: 1.5em;
  vertical-align: text-bottom;
}
</style>
