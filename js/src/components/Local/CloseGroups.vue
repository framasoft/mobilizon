<template>
  <close-content v-show="loadingGroups || selectedGroups.length > 0">
    <template #title>
      {{
        $t("Popular groups nearby {position}", {
          position: userLocationName,
        })
      }}
    </template>
    <template #content>
      <!-- <skeleton-group-result
        v-for="i in [...Array(6).keys()]"
        class="scroll-ml-6 snap-center shrink-0 w-[18rem] my-4"
        :key="i"
        v-show="loadingGroups"
      /> -->
      <group-result
        v-for="group in selectedGroups"
        :key="group.id"
        class="scroll-ml-6 snap-center shrink-0 first:pl-8 last:pr-8 w-[18rem]"
        :group="group"
        :view-mode="'column'"
        :minimal="true"
        :has-border="true"
      />

      <more-content
        v-if="userLocation"
        :to="{
          name: 'SEARCH',
          query: {
            locationName: userLocationName,
            lat: userLocation.lat,
            lon: userLocation.lon,
            contentType: 'GROUPS',
            distance: currentDistance,
          },
        }"
        :picture="userLocation.picture"
      >
        {{
          $t("View more groups around {position}", {
            position: userLocationName,
          })
        }}
      </more-content>
    </template>
  </close-content>
</template>

<script lang="ts">
import { defineComponent, inject, reactive, computed, ref } from "vue";
// import SkeletonGroupResult from "../../components/result/SkeletonGroupResult.vue";
import sampleSize from "lodash/sampleSize";
import { LocationType } from "../../types/user-location.model";
import MoreContent from "./MoreContent.vue";
import CloseContent from "./CloseContent.vue";
import { IGroup } from "@/types/actor";
import { SEARCH_GROUPS } from "@/graphql/search";

export default defineComponent({
  components: {
    MoreContent,
    CloseContent,
    // SkeletonGroupResult,
  },
  apollo: {
    groups: {
      query: SEARCH_GROUPS,
    },
  },
  setup() {
    const userLocationInjection = inject<{
      userLocation: LocationType;
    }>("userLocation");

    const groups = reactive<IGroup[]>([]);

    const selectedGroups = computed(() => sampleSize(groups, 5));

    const currentDistance = ref("25_km");

    const userLocationName = computed(
      () => userLocationInjection?.userLocation?.name
    );

    return {
      selectedGroups,
      userLocation: userLocationInjection?.userLocation,
      userLocationName,
      currentDistance,
    };
  },
});
</script>
