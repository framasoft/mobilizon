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
      <div class="flex flex-wrap gap-4">
        <div>
          <h2>{{ t("Last published event") }}</h2>
          <event-card
            v-if="dashboard?.lastPublicEventPublished"
            :event="dashboard?.lastPublicEventPublished"
          />
        </div>
        <div>
          <h2>{{ t("Last group created") }}</h2>
          <group-card
            v-if="dashboard?.lastGroupCreated"
            :group="dashboard?.lastGroupCreated"
          />
        </div>
      </div>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { DASHBOARD } from "@/graphql/admin";
import { IDashboard } from "@/types/admin.model";
import RouteName from "@/router/name";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import NumberDashboardTile from "@/components/Dashboard/NumberDashboardTile.vue";
import LinkedNumberDashboardTile from "@/components/Dashboard/LinkedNumberDashboardTile.vue";
import { InstanceFilterFollowStatus } from "@/types/enums";
import GroupCard from "@/components/Group/GroupCard.vue";
import EventCard from "@/components/Event/EventCard.vue";

const { result: dashboardResult } = useQuery<{ dashboard: IDashboard }>(
  DASHBOARD
);

const dashboard = computed(() => dashboardResult.value?.dashboard);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Administration")),
});
</script>
