import {
  IAnalyticsConfig,
  IConfig,
  IKeyValueConfig,
} from "@/types/config.model";

export const statistics = async (config: IConfig, environement: any) => {
  console.debug("Loading statistics", config.analytics);
  const matomoConfig = checkProviderConfig(config, "matomo");
  if (matomoConfig?.enabled === true) {
    const { matomo } = (await import("./matomo")) as any;
    matomo(environement, convertConfig(matomoConfig.configuration));
  }

  const sentryConfig = checkProviderConfig(config, "sentry");
  if (sentryConfig?.enabled === true) {
    const { sentry } = (await import("./sentry")) as any;
    sentry(environement, convertConfig(sentryConfig.configuration));
  }
};

export const checkProviderConfig = (
  config: IConfig,
  providerName: string
): IAnalyticsConfig | undefined => {
  return config?.analytics?.find((provider) => provider.id === providerName);
};

export const convertConfig = (
  configs: IKeyValueConfig[]
): Record<string, any> => {
  return configs.reduce((acc, config) => {
    acc[config.key] = toType(config.value, config.type);
    return acc;
  }, {} as Record<string, any>);
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
