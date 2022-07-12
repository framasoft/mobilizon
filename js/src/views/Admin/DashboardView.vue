<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        { text: t('Dashboard') },
      ]"
    />
    <section>
      <h1>{{ t("Administration") }}</h1>
      <div
        class="grid grid-cols-1 lg:grid-rows-2 lg:grid-flow-col gap-x-4 items-stretch"
      >
        <NumberDashboardTile :number="dashboard?.numberOfEvents">
          <template #subtitle>
            <i18n-t
              keypath="Published events with {comments} comments and {participations} confirmed participations"
              tag="p"
            >
              <template #comments>
                <b>{{ dashboard?.numberOfComments }}</b>
              </template>
              <template #participations>
                <b>{{
                  dashboard?.numberOfConfirmedParticipationsToLocalEvents
                }}</b>
              </template>
            </i18n-t>
          </template>
        </NumberDashboardTile>
        <LinkedNumberDashboardTile
          :number="dashboard?.numberOfGroups"
          :subtitle="t('Groups', dashboard?.numberOfGroups ?? 0)"
          :to="{ name: RouteName.ADMIN_GROUPS }"
        />
        <LinkedNumberDashboardTile
          :number="dashboard?.numberOfUsers"
          :subtitle="t('Users', dashboard?.numberOfUsers ?? 0)"
          :to="{ name: RouteName.ADMIN_GROUPS }"
        />
        <LinkedNumberDashboardTile
          :number="dashboard?.numberOfReports"
          :subtitle="t('Opened reports', dashboard?.numberOfReports ?? 0)"
          :to="{ name: RouteName.REPORTS }"
        />
        <LinkedNumberDashboardTile
          :number="dashboard?.numberOfFollowers"
          :subtitle="
            t('Instances following you', dashboard?.numberOfFollowers ?? 0)
          "
          :to="{
            name: RouteName.INSTANCES,
            query: { followStatus: InstanceFilterFollowStatus.FOLLOWING },
          }"
        />
        <LinkedNumberDashboardTile
          :number="dashboard?.numberOfFollowings"
          :subtitle="
            t('Instances you follow', dashboard?.numberOfFollowings ?? 0)
          "
          :to="{
            name: RouteName.INSTANCES,
            query: { followStatus: InstanceFilterFollowStatus.FOLLOWED },
          }"
        />
      </div>
      <div class="tile">
        <div
          class="tile is-parent is-vertical is-6"
          v-if="dashboard?.lastPublicEventPublished"
        >
          <article class="tile is-child box">
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: dashboard?.lastPublicEventPublished.uuid },
              }"
            >
              <p>{{ t("Last published event") }}</p>
              <p>
                {{ dashboard?.lastPublicEventPublished.title }}
              </p>
              <figure
                class="image is-4by3"
                v-if="dashboard?.lastPublicEventPublished.picture"
              >
                <img :src="dashboard?.lastPublicEventPublished.picture.url" />
              </figure>
            </router-link>
          </article>
        </div>
        <div
          class="tile is-parent is-vertical"
          v-if="dashboard?.lastGroupCreated"
        >
          <article class="tile is-child box">
            <router-link
              :to="{
                name: RouteName.GROUP,
                params: {
                  preferredUsername: usernameWithDomain(
                    dashboard?.lastGroupCreated
                  ),
                },
              }"
            >
              <p>{{ t("Last group created") }}</p>
              <p>
                {{
                  dashboard?.lastGroupCreated.name ||
                  dashboard?.lastGroupCreated.preferredUsername
                }}
              </p>
              <figure
                class="image is-4by3"
                v-if="dashboard?.lastGroupCreated.avatar"
              >
                <img :src="dashboard?.lastGroupCreated.avatar.url" />
              </figure>
            </router-link>
          </article>
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
import NumberDashboardTile from "@/components/Dashboard/NumberDashboardTile.vue";
import LinkedNumberDashboardTile from "@/components/Dashboard/LinkedNumberDashboardTile.vue";
import { InstanceFilterFollowStatus } from "@/types/enums";

const { result: dashboardResult } = useQuery<{ dashboard: IDashboard }>(
  DASHBOARD
);

const dashboard = computed(() => dashboardResult.value?.dashboard);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Administration")),
});
</script>
