import { IAnalyticsConfig, IKeyValueConfig } from "@/types/config.model";

let app: any = null;

export const setAppForAnalytics = (newApp: any) => {
  app = newApp;
};

export const statistics = async (
  configAnalytics: IAnalyticsConfig[],
  environement: any
) => {
  console.debug("Loading statistics", configAnalytics);
  const matomoConfig = checkProviderConfig(configAnalytics, "matomo");
  if (matomoConfig?.enabled === true) {
    const { matomo } = (await import("./matomo")) as any;
    matomo({ ...environement, app }, convertConfig(matomoConfig.configuration));
  }

  const sentryConfig = checkProviderConfig(configAnalytics, "sentry");
  if (sentryConfig?.enabled === true) {
    const { sentry } = (await import("./sentry")) as any;
    sentry({ ...environement, app }, convertConfig(sentryConfig.configuration));
  }
};

export const checkProviderConfig = (
  configAnalytics: IAnalyticsConfig[],
  providerName: string
): IAnalyticsConfig | undefined => {
  return configAnalytics?.find((provider) => provider.id === providerName);
};

export const convertConfig = (
  configs: IKeyValueConfig[]
): Record<string, any> => {
  return configs.reduce(
    (acc, config) => {
      acc[config.key] = toType(config.value, config.type);
      return acc;
    },
    {} as Record<string, any>
  );
};

const toType = (value: string, type: string): string | number | boolean => {
  switch (type) {
    case "boolean":
      return value === "true";
    case "integer":
      return parseInt(value, 10);
    case "float":
      return parseFloat(value);
    case "string":
    default:
      return value;
  }
};
