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
          <router-link :to="{ name: RouteName.REPORT_LOGS }">{{
            $t("Moderation log")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section v-if="actionLogs.total > 0 && actionLogs.elements.length > 0">
      <ul>
        <li v-for="log in actionLogs.elements" :key="log.id">
          <div class="box">
            <img
              class="image"
              :src="log.actor.avatar.url"
              v-if="log.actor.avatar"
            />
            <i18n
              v-if="log.action === ActionLogAction.REPORT_UPDATE_CLOSED"
              tag="span"
              path="{moderator} closed {report}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                :to="{
                  name: RouteName.REPORT,
                  params: { reportId: log.object.id },
                }"
                slot="report"
                >{{
                  $t("report #{report_number}", {
                    report_number: log.object.id,
                  })
                }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="log.action === ActionLogAction.REPORT_UPDATE_OPENED"
              tag="span"
              path="{moderator} reopened {report}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                :to="{
                  name: RouteName.REPORT,
                  params: { reportId: log.object.id },
                }"
                slot="report"
                >{{
                  $t("report #{report_number}", {
                    report_number: log.object.id,
                  })
                }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="log.action === ActionLogAction.REPORT_UPDATE_RESOLVED"
              tag="span"
              path="{moderator} marked {report} as resolved"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                :to="{
                  name: RouteName.REPORT,
                  params: { reportId: log.object.id },
                }"
                slot="report"
                >{{
                  $t("report #{report_number}", {
                    report_number: log.object.id,
                  })
                }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="log.action === ActionLogAction.NOTE_CREATION"
              tag="span"
              path="{moderator} added a note on {report}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                v-if="log.object.report"
                :to="{
                  name: RouteName.REPORT,
                  params: { reportId: log.object.report.id },
                }"
                slot="report"
                >{{
                  $t("report #{report_number}", {
                    report_number: log.object.report.id,
                  })
                }}
              </router-link>
              <span v-else slot="report">{{
                $t("a non-existent report")
              }}</span>
            </i18n>
            <i18n
              v-else-if="log.action === ActionLogAction.EVENT_DELETION"
              tag="span"
              path='{moderator} deleted an event named "{title}"'
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <b slot="title">{{ log.object.title }}</b>
            </i18n>
            <i18n
              v-else-if="
                log.action === ActionLogAction.ACTOR_SUSPENSION &&
                log.object.__typename == 'Person'
              "
              tag="span"
              path="{moderator} suspended profile {profile}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                slot="profile"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.object.id },
                }"
                >{{ displayNameAndUsername(log.object) }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="
                log.action === ActionLogAction.ACTOR_UNSUSPENSION &&
                log.object.__typename == 'Person'
              "
              tag="span"
              path="{moderator} has unsuspended profile {profile}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                slot="profile"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.object.id },
                }"
                >{{ displayNameAndUsername(log.object) }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="
                log.action === ActionLogAction.ACTOR_SUSPENSION &&
                log.object.__typename == 'Group'
              "
              tag="span"
              path="{moderator} suspended group {profile}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                slot="profile"
                :to="{
                  name: RouteName.ADMIN_GROUP_PROFILE,
                  params: { id: log.object.id },
                }"
                >{{ displayNameAndUsername(log.object) }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="
                log.action === ActionLogAction.ACTOR_UNSUSPENSION &&
                log.object.__typename == 'Group'
              "
              tag="span"
              path="{moderator} has unsuspended group {profile}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                slot="profile"
                :to="{
                  name: RouteName.ADMIN_GROUP_PROFILE,
                  params: { id: log.object.id },
                }"
                >{{ displayNameAndUsername(log.object) }}
              </router-link>
            </i18n>
            <i18n
              v-else-if="log.action === ActionLogAction.USER_DELETION"
              tag="span"
              path="{moderator} has deleted user {user}"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
              <router-link
                v-if="log.object.confirmedAt"
                slot="user"
                :to="{
                  name: RouteName.ADMIN_USER_PROFILE,
                  params: { id: log.object.id },
                }"
                >{{ log.object.email }}
              </router-link>
              <b v-else slot="user">{{ log.object.email }}</b>
            </i18n>
            <span
              v-else-if="
                log.action === ActionLogAction.COMMENT_DELETION &&
                log.object.event
              "
            >
              <i18n
                tag="span"
                path="{moderator} has deleted a comment from {author} under the event {event}"
              >
                <router-link
                  slot="moderator"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: log.actor.id },
                  }"
                  >@{{ log.actor.preferredUsername }}</router-link
                >
                <router-link
                  v-if="log.object.event && log.object.event.uuid"
                  slot="event"
                  :to="{
                    name: RouteName.EVENT,
                    params: { uuid: log.object.event.uuid },
                  }"
                  >{{ log.object.event.title }}
                </router-link>
                <b v-else slot="event">{{ log.object.event.title }}</b>
                <router-link
                  slot="author"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: log.object.actor.id },
                  }"
                  >{{ displayNameAndUsername(log.object.actor) }}
                </router-link>
              </i18n>
              <pre v-html="log.object.text" />
            </span>
            <span v-else-if="log.action === ActionLogAction.COMMENT_DELETION">
              <i18n
                tag="span"
                path="{moderator} has deleted a comment from {author}"
              >
                <router-link
                  slot="moderator"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: log.actor.id },
                  }"
                  >@{{ log.actor.preferredUsername }}</router-link
                >
                <router-link
                  slot="author"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: log.object.actor.id },
                  }"
                  >{{ displayNameAndUsername(log.object.actor) }}
                </router-link>
              </i18n>
              <pre v-html="log.object.text" />
            </span>
            <i18n
              v-else
              tag="span"
              path="{moderator} has done an unknown action"
            >
              <router-link
                slot="moderator"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: log.actor.id },
                }"
                >@{{ log.actor.preferredUsername }}</router-link
              >
            </i18n>
            <br />
            <small>{{ log.insertedAt | formatDateTimeString }}</small>
          </div>
        </li>
      </ul>
      <b-pagination
        :total="actionLogs.total"
        v-model="page"
        :per-page="LOGS_PER_PAGE"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      >
      </b-pagination>
    </section>
    <div v-else>
      <b-message type="is-info">{{ $t("No moderation logs yet") }}</b-message>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { IActionLog } from "@/types/report.model";
import { LOGS } from "@/graphql/report";
import ReportCard from "@/components/Report/ReportCard.vue";
import { ActionLogAction } from "@/types/enums";
import RouteName from "../../router/name";
import { displayNameAndUsername } from "../../types/actor";
import { Paginate } from "@/types/paginate";

@Component({
  components: {
    ReportCard,
  },
  apollo: {
    actionLogs: {
      fetchPolicy: "cache-and-network",
      query: LOGS,
      variables() {
        return {
          page: this.page,
          limit: this.LOGS_PER_PAGE,
        };
      },
    },
  },
})
export default class ReportList extends Vue {
  actionLogs?: Paginate<IActionLog> = { total: 0, elements: [] };

  page = parseInt((this.$route.query.page as string) || "1", 10);

  LOGS_PER_PAGE = 10;

  ActionLogAction = ActionLogAction;

  RouteName = RouteName;

  displayNameAndUsername = displayNameAndUsername;

  mounted(): void {
    this.page = parseInt((this.$route.query.page as string) || "1", 10);
  }

  @Watch("page")
  triggerLoadMoreMemberPageChange(page: string): void {
    this.$router.replace({
      name: RouteName.REPORT_LOGS,
      query: { ...this.$route.query, page },
    });
  }
}
</script>
<style lang="scss" scoped>
img.image {
  display: inline-block;
  height: 1.5em;
  vertical-align: text-bottom;
}

a {
  text-decoration: none;
}

section ul li {
  margin: 0.5rem auto;
}
</style>
