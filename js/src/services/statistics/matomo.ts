import VueMatomo from "vue-matomo";

export const matomo = (environment: any, matomoConfiguration: any) => {
  console.debug("Loading Matomo statistics");
  console.debug(
    "Calling VueMatomo with the following configuration",
    matomoConfiguration
  );
  environment.app.use(VueMatomo, {
    ...matomoConfiguration,
    router: environment.router,
    debug: import.meta.env.DEV,
  });
};
