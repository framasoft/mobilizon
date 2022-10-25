<template>
  <div>
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.MODERATION,
          text: $t('Moderation'),
        },
        {
          name: RouteName.REPORT_LOGS,
          text: $t('Moderation log'),
        },
      ]"
    />
    <section v-if="actionLogs.total > 0 && actionLogs.elements.length > 0">
      <ul>
        <li
          v-for="log in actionLogs.elements"
          :key="log.id"
          class="bg-mbz-yellow-alt-50 hover:bg-mbz-yellow-alt-100 dark:bg-zinc-700 hover:dark:bg-zinc-600 rounded p-2 my-1"
        >
          <div class="flex gap-1">
            <div class="flex gap-1">
              <figure class="" v-if="log.actor?.avatar">
                <img
                  alt=""
                  :src="log.actor.avatar?.url"
                  class="rounded-full"
                  width="36"
                  height="36"
                />
              </figure>
              <AccountCircle v-else :size="36" />
            </div>
            <div>
              <i18n-t
                v-if="log.action === ActionLogAction.REPORT_UPDATE_CLOSED"
                tag="span"
                keypath="{moderator} closed {report}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #report>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.REPORT,
                      params: { reportId: log.object.id },
                    }"
                    >{{
                      $t("report #{report_number}", {
                        report_number: log.object.id,
                      })
                    }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="log.action === ActionLogAction.REPORT_UPDATE_OPENED"
                tag="span"
                keypath="{moderator} reopened {report}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #report>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.REPORT,
                      params: { reportId: log.object.id },
                    }"
                    >{{
                      $t("report #{report_number}", {
                        report_number: log.object.id,
                      })
                    }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="
                  log.action === ActionLogAction.REPORT_UPDATE_RESOLVED
                "
                tag="span"
                keypath="{moderator} marked {report} as resolved"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #report>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.REPORT,
                      params: { reportId: log.object.id },
                    }"
                    >{{
                      $t("report #{report_number}", {
                        report_number: log.object.id,
                      })
                    }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="log.action === ActionLogAction.NOTE_CREATION"
                tag="span"
                keypath="{moderator} added a note on {report}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #report>
                  <router-link
                    class="underline"
                    v-if="log.object.report"
                    :to="{
                      name: RouteName.REPORT,
                      params: { reportId: log.object.report.id },
                    }"
                    >{{
                      $t("report #{report_number}", {
                        report_number: log.object.report.id,
                      })
                    }}
                  </router-link>
                  <span v-else>{{ $t("a non-existent report") }}</span>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="log.action === ActionLogAction.EVENT_DELETION"
                tag="span"
                keypath='{moderator} deleted an event named "{title}"'
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #title>
                  <b>{{ log.object.title }}</b>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="
                  log.action === ActionLogAction.ACTOR_SUSPENSION &&
                  log.object.__typename == 'Person'
                "
                tag="span"
                keypath="{moderator} suspended profile {profile}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #profile>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.object.id },
                    }"
                    >{{ displayNameAndUsername(log.object) }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="
                  log.action === ActionLogAction.ACTOR_UNSUSPENSION &&
                  log.object.__typename == 'Person'
                "
                tag="span"
                keypath="{moderator} has unsuspended profile {profile}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #profile>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.object.id },
                    }"
                    >{{ displayNameAndUsername(log.object) }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="
                  log.action === ActionLogAction.ACTOR_SUSPENSION &&
                  log.object.__typename == 'Group'
                "
                tag="span"
                keypath="{moderator} suspended group {profile}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #profile>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_GROUP_PROFILE,
                      params: { id: log.object.id },
                    }"
                    >{{ displayNameAndUsername(log.object) }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="
                  log.action === ActionLogAction.ACTOR_UNSUSPENSION &&
                  log.object.__typename == 'Group'
                "
                tag="span"
                keypath="{moderator} has unsuspended group {profile}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #profile>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_GROUP_PROFILE,
                      params: { id: log.object.id },
                    }"
                    >{{ displayNameAndUsername(log.object) }}
                  </router-link>
                </template>
              </i18n-t>
              <i18n-t
                v-else-if="log.action === ActionLogAction.USER_DELETION"
                tag="span"
                keypath="{moderator} has deleted user {user}"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
                <template #user>
                  <router-link
                    class="underline"
                    v-if="log.object.confirmedAt"
                    :to="{
                      name: RouteName.ADMIN_USER_PROFILE,
                      params: { id: log.object.id },
                    }"
                    >{{ log.object.email }}
                  </router-link>
                  <b v-else>{{ log.object.email }}</b>
                </template>
              </i18n-t>
              <span
                v-else-if="
                  log.action === ActionLogAction.COMMENT_DELETION &&
                  log.object.event
                "
              >
                <i18n-t
                  tag="span"
                  keypath="{moderator} has deleted a comment from {author} under the event {event}"
                >
                  <template #moderator>
                    <router-link
                      class="underline"
                      :to="{
                        name: RouteName.ADMIN_PROFILE,
                        params: { id: log.actor.id },
                      }"
                      >{{ displayName(log.actor) }}</router-link
                    >
                  </template>
                  <template #event>
                    <router-link
                      class="underline"
                      v-if="log.object.event && log.object.event.uuid"
                      :to="{
                        name: RouteName.EVENT,
                        params: { uuid: log.object.event.uuid },
                      }"
                      >{{ log.object.event.title }}
                    </router-link>
                    <b v-else>{{ log.object.event.title }}</b>
                  </template>
                  <template #author>
                    <router-link
                      class="underline"
                      :to="{
                        name: RouteName.ADMIN_PROFILE,
                        params: { id: log.object.actor.id },
                      }"
                      >{{ displayNameAndUsername(log.object.actor) }}
                    </router-link>
                  </template>
                </i18n-t>
                <pre v-html="log.object.text" />
              </span>
              <span v-else-if="log.action === ActionLogAction.COMMENT_DELETION">
                <i18n-t
                  tag="span"
                  keypath="{moderator} has deleted a comment from {author}"
                >
                  <template #moderator>
                    <router-link
                      class="underline"
                      :to="{
                        name: RouteName.ADMIN_PROFILE,
                        params: { id: log.actor.id },
                      }"
                      >{{ displayName(log.actor) }}</router-link
                    >
                  </template>
                  <template #author>
                    <router-link
                      class="underline"
                      :to="{
                        name: RouteName.ADMIN_PROFILE,
                        params: { id: log.object.actor.id },
                      }"
                      >{{ displayNameAndUsername(log.object.actor) }}
                    </router-link>
                  </template>
                </i18n-t>
                <pre v-html="log.object.text" />
              </span>
              <i18n-t
                v-else
                tag="span"
                keypath="{moderator} has done an unknown action"
              >
                <template #moderator>
                  <router-link
                    class="underline"
                    :to="{
                      name: RouteName.ADMIN_PROFILE,
                      params: { id: log.actor.id },
                    }"
                    >{{ displayName(log.actor) }}</router-link
                  >
                </template>
              </i18n-t>
              <br />
              <small>{{ formatDateTimeString(log.insertedAt) }}</small>
            </div>
          </div>
        </li>
      </ul>
      <o-pagination
        :total="actionLogs.total"
        v-model="page"
        :per-page="LOGS_PER_PAGE"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      >
      </o-pagination>
    </section>
    <div v-else>
      <o-notification variant="info">{{
        $t("No moderation logs yet")
      }}</o-notification>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IActionLog } from "@/types/report.model";
import { LOGS } from "@/graphql/report";
import { ActionLogAction } from "@/types/enums";
import RouteName from "../../router/name";
import { displayNameAndUsername, displayName } from "../../types/actor";
import { Paginate } from "@/types/paginate";
import { useQuery } from "@vue/apollo-composable";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { useHead } from "@vueuse/head";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { formatDateTimeString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";

const LOGS_PER_PAGE = 10;

const page = useRouteQuery("page", 1, integerTransformer);

const { result: actionLogsResult } = useQuery<{
  actionLogs: Paginate<IActionLog>;
}>(LOGS, () => ({
  page: page.value,
  limit: LOGS_PER_PAGE,
}));

const actionLogs = computed(
  () => actionLogsResult.value?.actionLogs ?? { total: 0, elements: [] }
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Moderation logs")),
});
</script>
<style lang="scss" scoped>
img.image {
  display: inline-block;
  height: 1.5em;
  vertical-align: text-bottom;
}

section ul li {
  margin: 0.5rem auto;
}
</style>
