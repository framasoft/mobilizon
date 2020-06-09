<template>
  <section>
    <ul v-if="actionLogs.length > 0">
      <li v-for="log in actionLogs" :key="log.id">
        <div class="box">
          <img class="image" :src="log.actor.avatar.url" v-if="log.actor.avatar" />
          <i18n
            v-if="log.action === ActionLogAction.REPORT_UPDATE_CLOSED"
            tag="span"
            path="{actor} closed {report}"
          >
            <span slot="actor">@{{ log.actor.preferredUsername }}</span>
            <router-link
              :to="{ name: RouteName.REPORT, params: { reportId: log.object.id } }"
              slot="report"
              >{{ $t("report #{report_number}", { report_number: log.object.id }) }}
            </router-link>
          </i18n>
          <i18n
            v-else-if="log.action === ActionLogAction.REPORT_UPDATE_OPENED"
            tag="span"
            path="{actor} reopened {report}"
          >
            <span slot="actor">@{{ log.actor.preferredUsername }}</span>
            <router-link
              :to="{ name: RouteName.REPORT, params: { reportId: log.object.id } }"
              slot="report"
              >{{ $t("report #{report_number}", { report_number: log.object.id }) }}
            </router-link>
          </i18n>
          <i18n
            v-else-if="log.action === ActionLogAction.REPORT_UPDATE_RESOLVED"
            tag="span"
            path="{actor} marked {report} as resolved"
          >
            <span slot="actor">@{{ log.actor.preferredUsername }}</span>
            <router-link
              :to="{ name: RouteName.REPORT, params: { reportId: log.object.id } }"
              slot="report"
              >{{ $t("report #{report_number}", { report_number: log.object.id }) }}
            </router-link>
          </i18n>
          <i18n
            v-else-if="log.action === ActionLogAction.NOTE_CREATION"
            tag="span"
            path="{actor} added a note on {report}"
          >
            <span slot="actor">@{{ log.actor.preferredUsername }}</span>
            <router-link
              v-if="log.object.report"
              :to="{ name: RouteName.REPORT, params: { reportId: log.object.report.id } }"
              slot="report"
              >{{ $t("report #{report_number}", { report_number: log.object.report.id }) }}
            </router-link>
            <span v-else slot="report">{{ $t("a non-existent report") }}</span>
          </i18n>
          <i18n
            v-else-if="log.action === ActionLogAction.EVENT_DELETION"
            tag="span"
            path='{actor} deleted an event named "{title}"'
          >
            <span slot="actor">@{{ log.actor.preferredUsername }}</span>
            <span slot="title">{{ log.object.title }}</span>
          </i18n>
          <br />
          <small>{{ log.insertedAt | formatDateTimeString }}</small>
        </div>
      </li>
    </ul>
    <div v-else>
      <b-message type="is-info">{{ $t("No moderation logs yet") }}</b-message>
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
  display: inline-block;
  height: 1.5em;
  vertical-align: text-bottom;
}
</style>
