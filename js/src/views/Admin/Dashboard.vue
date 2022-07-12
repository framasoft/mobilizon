<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: $t('Admin') },
        { text: $t('Dashboard') },
      ]"
    />
    <section>
      <h1>{{ $t("Administration") }}</h1>
      <div class="tile is-ancestor" v-if="dashboard">
        <div class="tile is-vertical">
          <div class="tile">
            <div class="tile is-parent is-vertical is-6">
              <article class="tile is-child box">
                <p class="dashboard-number">{{ dashboard.numberOfEvents }}</p>
                <i18n-t
                  keypath="Published events with {comments} comments and {participations} confirmed participations"
                  tag="p"
                >
                  <template #comments>
                    <b>{{ dashboard.numberOfComments }}</b>
                  </template>
                  <template #participations>
                    <b>{{
                      dashboard.numberOfConfirmedParticipationsToLocalEvents
                    }}</b>
                  </template>
                </i18n-t>
              </article>
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.ADMIN_GROUPS }">
                  <p class="dashboard-number">{{ dashboard.numberOfGroups }}</p>
                  <p>{{ $t("Groups") }}</p>
                </router-link>
              </article>
            </div>
            <div class="tile is-parent is-vertical">
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.USERS }">
                  <p class="dashboard-number">{{ dashboard.numberOfUsers }}</p>
                  <p>{{ $t("Users") }}</p>
                </router-link>
              </article>
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.RELAY_FOLLOWERS }">
                  <p class="dashboard-number">
                    {{ dashboard.numberOfFollowers }}
                  </p>
                  <p>{{ $t("Instances following you") }}</p>
                </router-link>
              </article>
            </div>
            <div class="tile is-parent is-vertical">
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.REPORTS }">
                  <p class="dashboard-number">
                    {{ dashboard.numberOfReports }}
                  </p>
                  <p>{{ $t("Opened reports") }}</p>
                </router-link>
              </article>
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.RELAY_FOLLOWINGS }">
                  <p class="dashboard-number">
                    {{ dashboard.numberOfFollowings }}
                  </p>
                  <p>{{ $t("Instances you follow") }}</p>
                </router-link>
              </article>
            </div>
          </div>
          <div class="tile">
            <div
              class="tile is-parent is-vertical is-6"
              v-if="dashboard.lastPublicEventPublished"
            >
              <article class="tile is-child box">
                <router-link
                  :to="{
                    name: RouteName.EVENT,
                    params: { uuid: dashboard.lastPublicEventPublished.uuid },
                  }"
                >
                  <p>{{ $t("Last published event") }}</p>
                  <p class="subtitle">
                    {{ dashboard.lastPublicEventPublished.title }}
                  </p>
                  <figure
                    class="image is-4by3"
                    v-if="dashboard.lastPublicEventPublished.picture"
                  >
                    <img
                      :src="dashboard.lastPublicEventPublished.picture.url"
                    />
                  </figure>
                </router-link>
              </article>
            </div>
            <div
              class="tile is-parent is-vertical"
              v-if="dashboard.lastGroupCreated"
            >
              <article class="tile is-child box">
                <router-link
                  :to="{
                    name: RouteName.GROUP,
                    params: {
                      preferredUsername: usernameWithDomain(
                        dashboard.lastGroupCreated
                      ),
                    },
                  }"
                >
                  <p>{{ $t("Last group created") }}</p>
                  <p class="subtitle">
                    {{
                      dashboard.lastGroupCreated.name ||
                      dashboard.lastGroupCreated.preferredUsername
                    }}
                  </p>
                  <figure
                    class="image is-4by3"
                    v-if="dashboard.lastGroupCreated.avatar"
                  >
                    <img :src="dashboard.lastGroupCreated.avatar.url" />
                  </figure>
                </router-link>
              </article>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { DASHBOARD } from "@/graphql/admin";
import { IDashboard } from "@/types/admin.model";
import { usernameWithDomain } from "@/types/actor";
import RouteName from "@/router/name";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const { result: dashboardResult } = useQuery<{ dashboard: IDashboard }>(
  DASHBOARD
);

const dashboard = computed(() => dashboardResult.value?.dashboard);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Administration")),
});
</script>

<style lang="scss" scoped>
.dashboard-number {
  font-size: 40px;
  font-weight: 700;
  line-height: 1.125;
}

.tile a,
article.tile a {
  text-decoration: none;
}

.image.is-4by3 img {
  object-fit: cover;
}
</style>
