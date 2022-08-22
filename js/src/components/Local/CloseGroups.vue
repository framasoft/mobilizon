<template>
  <close-content
    class="container mx-auto px-2"
    v-show="loadingGroups || selectedGroups.length > 0"
    @do-geo-loc="emit('doGeoLoc')"
    :suggestGeoloc="userLocation.isIPLocation"
  >
    <template #title>
      <template v-if="userLocationName">
        {{
          t("Popular groups nearby {position}", {
            position: userLocationName,
          })
        }}
      </template>
      <template v-else>
        {{ t("Popular groups close to you") }}
      </template>
    </template>
    <template #content>
      <!-- <skeleton-group-result
        v-for="i in [...Array(6).keys()]"
        class="scroll-ml-6 snap-center shrink-0 w-[18rem] my-4"
        :key="i"
        v-show="loadingGroups"
      /> -->
      <group-card
        v-for="group in selectedGroups"
        :key="group.id"
        :group="group"
        :view-mode="'column'"
        :minimal="true"
        :has-border="true"
        :showSummary="false"
      />

      <more-content
        v-if="userLocationName"
        :to="{
          name: 'SEARCH',
          query: {
            locationName: userLocationName,
            lat: userLocation.lat?.toString(),
            lon: userLocation.lon?.toString(),
            contentType: 'GROUPS',
            distance: '25_km',
          },
        }"
        :picture="userLocation.picture"
      >
        {{
          t("View more groups around {position}", {
            position: userLocationName,
          })
        }}
      </more-content>
    </template>
  </close-content>
</template>

<script lang="ts" setup>
// import SkeletonGroupResult from "../../components/result/SkeletonGroupResult.vue";
import sampleSize from "lodash/sampleSize";
import { LocationType } from "../../types/user-location.model";
import MoreContent from "./MoreContent.vue";
import CloseContent from "./CloseContent.vue";
import { IGroup } from "@/types/actor";
import { SEARCH_GROUPS } from "@/graphql/search";
import { useQuery } from "@vue/apollo-composable";
import { Paginate } from "@/types/paginate";
import { computed } from "vue";
import GroupCard from "@/components/Group/GroupCard.vue";
import { coordsToGeoHash } from "@/utils/location";
import { useI18n } from "vue-i18n";

const props = defineProps<{ userLocation: LocationType }>();
const emit = defineEmits(["doGeoLoc"]);

const { t } = useI18n({ useScope: "global" });

const { result: groupsResult, loading: loadingGroups } = useQuery<{
  searchGroups: Paginate<IGroup>;
}>(
  SEARCH_GROUPS,
  () => ({
    location: coordsToGeoHash(props.userLocation.lat, props.userLocation.lon),
    radius: 25,
    page: 1,
    limit: 12,
  }),
  () => ({ enabled: props.userLocation?.lat !== undefined })
);

const groups = computed(
  () => groupsResult.value?.searchGroups ?? { total: 0, elements: [] }
);

const selectedGroups = computed(() => sampleSize(groups.value?.elements, 5));

const userLocationName = computed(() => props?.userLocation?.name);
</script>
