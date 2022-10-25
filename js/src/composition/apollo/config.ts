import {
  ABOUT,
  ANALYTICS,
  ANONYMOUS_ACTOR_ID,
  ANONYMOUS_PARTICIPATION_CONFIG,
  ANONYMOUS_REPORTS_CONFIG,
  DEMO_MODE,
  EVENT_CATEGORIES,
  EVENT_PARTICIPANTS,
  FEATURES,
  GEOCODING_AUTOCOMPLETE,
  LOCATION,
  MAPS_TILES,
  RESOURCE_PROVIDERS,
  RESTRICTIONS,
  ROUTING_TYPE,
  SEARCH_CONFIG,
  TIMEZONES,
  UPLOAD_LIMITS,
} from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";

export function useTimezones() {
  const {
    result: timezoneResult,
    error,
    loading,
  } = useQuery<{
    config: Pick<IConfig, "timezones">;
  }>(TIMEZONES, undefined, { fetchPolicy: "cache-first" });

  const timezones = computed(() => timezoneResult.value?.config?.timezones);
  return { timezones, error, loading };
}

export function useAnonymousParticipationConfig() {
  const {
    result: configResult,
    error,
    loading,
  } = useQuery<{
    config: Pick<IConfig, "anonymous">;
  }>(ANONYMOUS_PARTICIPATION_CONFIG, undefined, { fetchPolicy: "cache-only" });

  const anonymousParticipationConfig = computed(
    () => configResult.value?.config?.anonymous?.participation
  );

  return { anonymousParticipationConfig, error, loading };
}

export function useAnonymousReportsConfig() {
  const {
    result: configResult,
    error,
    loading,
  } = useQuery<{
    config: Pick<IConfig, "anonymous">;
  }>(ANONYMOUS_REPORTS_CONFIG, undefined, { fetchPolicy: "cache-only" });

  const anonymousReportsConfig = computed(
    () => configResult.value?.config?.anonymous?.reports
  );
  return { anonymousReportsConfig, error, loading };
}

export function useInstanceName() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "name">;
  }>(ABOUT, undefined, { fetchPolicy: "cache-only" });

  const instanceName = computed(() => result.value?.config?.name);
  return { instanceName, error, loading };
}

export function useAnonymousActorId() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "anonymous">;
  }>(ANONYMOUS_ACTOR_ID, undefined, { fetchPolicy: "cache-only" });

  const anonymousActorId = computed(
    () => result.value?.config?.anonymous?.actorId
  );
  return { anonymousActorId, error, loading };
}

export function useUploadLimits() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "uploadLimits">;
  }>(UPLOAD_LIMITS, undefined, { fetchPolicy: "cache-only" });

  const uploadLimits = computed(() => result.value?.config?.uploadLimits);
  return { uploadLimits, error, loading };
}

export function useEventCategories() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "eventCategories">;
  }>(EVENT_CATEGORIES, undefined, { fetchPolicy: "cache-only" });

  const eventCategories = computed(() => result.value?.config.eventCategories);
  return { eventCategories, error, loading };
}

export function useRestrictions() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "restrictions">;
  }>(RESTRICTIONS, undefined, { fetchPolicy: "cache-only" });

  const restrictions = computed(() => result.value?.config.restrictions);
  return { restrictions, error, loading };
}

export function useExportFormats() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "exportFormats">;
  }>(EVENT_PARTICIPANTS, undefined, { fetchPolicy: "cache-only" });
  const exportFormats = computed(() => result.value?.config?.exportFormats);
  return { exportFormats, error, loading };
}

export function useGeocodingAutocomplete() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "geocoding">;
  }>(GEOCODING_AUTOCOMPLETE, undefined, { fetchPolicy: "cache-only" });
  const geocodingAutocomplete = computed(
    () => result.value?.config?.geocoding?.autocomplete
  );
  return { geocodingAutocomplete, error, loading };
}

export function useMapTiles() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "maps">;
  }>(MAPS_TILES, undefined, { fetchPolicy: "cache-only" });

  const tiles = computed(() => result.value?.config.maps.tiles);
  return { tiles, error, loading };
}

export function useRoutingType() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "maps">;
  }>(ROUTING_TYPE, undefined, { fetchPolicy: "cache-only" });

  const routingType = computed(() => result.value?.config.maps.routing.type);
  return { routingType, error, loading };
}

export function useFeatures() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "features">;
  }>(FEATURES, undefined, { fetchPolicy: "cache-only" });

  const features = computed(() => result.value?.config.features);
  return { features, error, loading };
}

export function useResourceProviders() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "resourceProviders">;
  }>(RESOURCE_PROVIDERS, undefined, { fetchPolicy: "cache-only" });

  const resourceProviders = computed(
    () => result.value?.config.resourceProviders
  );
  return { resourceProviders, error, loading };
}

export function useServerProvidedLocation() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "location">;
  }>(LOCATION, undefined, { fetchPolicy: "cache-only" });

  const location = computed(() => result.value?.config.location);
  return { location, error, loading };
}

export function useIsDemoMode() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "demoMode">;
  }>(DEMO_MODE, undefined, { fetchPolicy: "cache-only" });

  const isDemoMode = computed(() => result.value?.config.demoMode);
  return { isDemoMode, error, loading };
}

export function useAnalytics() {
  const { result, error, loading } = useQuery<{
    config: Pick<IConfig, "analytics">;
  }>(ANALYTICS, undefined, { fetchPolicy: "cache-only" });

  const analytics = computed(() => result.value?.config.analytics);
  return { analytics, error, loading };
}

export function useSearchConfig() {
  const { result, error, loading, onResult } = useQuery<{
    config: Pick<IConfig, "search">;
  }>(SEARCH_CONFIG, undefined, { fetchPolicy: "cache-only" });

  const searchConfig = computed(() => result.value?.config.search);
  return { searchConfig, error, loading, onResult };
}
